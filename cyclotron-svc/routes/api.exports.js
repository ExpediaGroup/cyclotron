/*
 * Copyright (c) 2013-2018 the original author or authors.
 *
 * Licensed under the MIT License (the "License");
 * you may not use this file except in compliance with the License. 
 * You may obtain a copy of the License at
 *
 *     http://www.opensource.org/licenses/mit-license.php
 *
 * Unless required by applicable law or agreed to in writing, 
 * software distributed under the License is distributed on an 
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
 * either express or implied. See the License for the specific 
 * language governing permissions and limitations under the License. 
 */ 
 
/* 
 * API for Exporting
 */

var _ = require('lodash'),
    mongoose = require('mongoose'),
    config = require('../config/config'),
    auth = require('./auth');

var Dashboards = mongoose.model('dashboard2');

var fs = require('fs'),
    childProcess = require('child_process'),
    ip = require('ip'),
    shortid = require('shortid'),
    json2csv = require('json2csv'),
    json2xls = require('json2xls');

/* String EndsWith implementation */
var endsWith = function (str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

/* Ensure exports directory exists */
var exportDirectory = __dirname + '/../export';
fs.existsSync(exportDirectory) || fs.mkdirSync(exportDirectory);

var exportKeys = {};

/* Exports a Dashboard as a PDF */
/* Handles sync and asych modes */
var exportPdf = function (req, res, sync) {

    var dashboardName = req.params.name.toLowerCase();
    Dashboards
        .findOne({ name: dashboardName })
        .select('-dashboard')
        .exec(function(err, dashboard) {
            if (err) {
                console.log(err);
                return res.status(500).send(err);
            } else if (_.isUndefined(dashboard) || _.isNull(dashboard)) {
                return res.status(404).send('Dashboard not found.');
            }

            if (!_.isEmpty(dashboard.viewers)) {
                if (auth.isUnauthenticated(req)) {
                    return res.status(401).send('Authentication required: this dashboard has restricted permissions.');
                }

                /* Check view permissions */
                if (!auth.hasViewPermission(dashboard, req)) {
                    return res.status(403).send('View Permission denied for this Dashboard.');
                }
            }

            /* View Permissions allowed */
            var queryIndex = req.url.indexOf('?')
            var query = queryIndex < 0 ? '' : req.url.substr(queryIndex);

            /* Construct dashboard URL */
            var dashboardUrl = config.webServer + '/' + dashboardName + query;

            /* Unique id for the report */
            var id = req.params.name + '-' + (new Date()).toISOString();

            /* Increase connection timeout: 15 minutes */
            req.connection.setTimeout(900*1000);

            console.log('Exporting dashboard: ' + dashboardUrl);

            var terminal = childProcess.spawn('casperjs', ['pdfexport.js', dashboardUrl, id]);

            exportKeys[id] = { status: 'running', startTime: Date.now() };

            terminal.on('close', function (code) {

                if (code < 0) {
                    err = 'pdf export error (code ' + code + ')';
                    console.log(err);
                    _.assign(exportKeys[id], { status: 'error', error: err, duration: Date.now() - exportKeys[id].startTime });

                    if (sync) { res.status(500).send(err); }

                } else {

                    _.assign(exportKeys[id], { status: 'complete', duration: Date.now() - exportKeys[id].startTime });

                    if (sync) {
                        /* Redirect to the generated report */
                        res.redirect(302, 'http://' + ip.address() + ':' + config.port + '/exports/' + id + '.pdf');
                    }
                }

                //res.sendfile('./export/' + id + '.pdf');
                //res.download('./export/' + id + '.pdf', req.params.name + '-' + date.toISOString() + '.pdf');
            });

            terminal.on('error', function (err) {
                console.log('pdf export error', err);
                _.assign(exportKeys[id], { status: 'error', error: err, duration: Date.now() - exportKeys[id].startTime });

                if (sync) { res.status(500).send(err); }
            });

            if (!sync) {
                res.status(201).send({ statusUrl: 'http://' + ip.address() + ':' + config.port + '/exportstatus/' + id });
            }
        });
};



/* Exports a Dashboard as a PDF */
exports.pdf = function (req, res) {
    exportPdf(req, res, true);
};

/* Exports a Dashboard as a PDF -- asynch */
exports.pdfAsync = function (req, res) {
    exportPdf(req, res, false);
};

/* Returns the status of an export */
exports.status = function (req, res) {
    var key = req.params.key;

    fs.readdir('export', function (err, files) {
        if (err) {
            console.log(err);
            res.status(500).send('Error reading export status: ' + err);
            return;
        }

        matchingFiles = _.filter(files, function (file) {
            return file.substring(0, key.length) == key;
        });

        matchingFiles = _.sortBy(matchingFiles, _.identity);

        matchingFiles = _.map(matchingFiles, function (file) {
            return 'http://' + ip.address() + ':' + config.port + '/exports/' + file;
        });

        var pngs = [],
            htmls = [],
            pdfs = [];

        _.each(matchingFiles, function (file) {
            if (endsWith(file, '.png')) {
                pngs.push(file);
            } else if (endsWith(file, '.html')) {
                htmls.push(file);
            } else if (endsWith(file, '.pdf')) {
                pdfs.push(file);
            }
        });

        var status = {
            status: 'unknown',
            png: pngs,
            html: htmls,
            pdf: pdfs
        };

        if (_.has(exportKeys, key)) {
            _.assign(status, exportKeys[key]);

            if (!_.has(status, 'duration')) {
                /* Calculate running duration */
                status.duration = Date.now() - status.startTime;
            }
        }

        res.send(status);
    });
};

/* Sends an exported report with the correct Content-Type headers */
exports.serve = function (req, res) {
    res.attachment(req.params.file);
    res.sendfile('./export/' + req.params.file);
};


/* Data Download:
 * Writes POSTED data to a file, then returns a key to download it.
 * Download file using /exports/:key 
 */
exports.dataAsync = function (req, res) {
    if (req.body == null) {
        return res.status(400).send('Missing body in request.');
    }

    if (req.body.format == null) {
        return res.status(400).send('Missing format in request.');
    }
    if (req.body.data == null) {
        return res.status(400).send('Missing data in request.');
    }

    switch (req.body.format.toLowerCase()) {
        case 'json': 
            /* Unique key for the file */
            var key = (req.body.name || 'data') + '-' + shortid.generate() + '.json',
                filename = './export/' + key;
            
            /* Write file and return key for download */
            fs.writeFile(filename, JSON.stringify(req.body.data, null, 4), 'utf8', function (err) {
                if (err) { 
                    console.log(err);
                    return res.status(500).send(err);
                }
                res.status(201).send({
                    url: 'http://' + ip.address() + ':' + config.port + '/exports/' + key
                });
            });
            
            break;
        case 'csv':
            /* Unique key for the file */
            var key = (req.body.name || 'data') + '-' + shortid.generate() + '.csv',
                filename = './export/' + key;
            
            /* Write file and return key for download */
            fs.writeFile(filename, json2csv({ data: req.body.data }), 'utf8', function (err) {
                if (err) { 
                    console.log(err);
                    return res.status(500).send(err);
                }
                res.status(201).send({
                    url: 'http://' + ip.address() + ':' + config.port + '/exports/' + key
                });
            });
            
            break;
        case 'xlsx':
            /* Unique key for the file */
            var key = (req.body.name || 'data') + '-' + shortid.generate() + '.xlsx',
                filename = './export/' + key;
            
            /* Write file and return key for download */
            fs.writeFile(filename, json2xls(req.body.data), 'binary', function (err) {
                if (err) { 
                    console.log(err);
                    return res.status(500).send(err);
                }
                res.status(201).send({
                    url: 'http://' + ip.address() + ':' + config.port + '/exports/' + key
                });
            });
            
            break;
        default:
            return res.status(400).send('Unknown format in request: "' + req.body.format.toLowerCase() + '".');
    }
};
