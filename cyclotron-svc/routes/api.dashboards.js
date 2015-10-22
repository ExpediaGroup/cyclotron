/*
 * Copyright (c) 2013-2015 the original author or authors.
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
 * API for Dashboards
 */

var _ = require('lodash'),
    mongoose = require('mongoose'),
    api = require('./api'),
    auth = require('./auth');
    
var Dashboards = mongoose.model('dashboard2'),
    Revisions = mongoose.model('revision');

var createRevision = function(dashboard) {
    /* Create new record in the Revision collection */
    var newRev = new Revisions({
        name: dashboard.name,
        rev: dashboard.rev,
        date: dashboard.date,
        deleted: dashboard.deleted,
        tags: dashboard.tags,
        description: dashboard.description || '',
        dashboard: dashboard.dashboard,
        createdBy: dashboard.createdBy,
        lastUpdatedBy: dashboard.lastUpdatedBy,
        editors: dashboard.editors,
        viewers: dashboard.viewers
    });

    newRev.save();
}

/* Output modified dashboard after an update */
var updateCallback = function (res, err, modifiedDashboard) {
    if (!err) {
        console.log('Updated: ' + modifiedDashboard.name);
        res.send(modifiedDashboard);

        createRevision(modifiedDashboard);
    } else {
        console.log(err);
        res.status(500).send(err);
    }
};

exports.getNames = function(req, res) {
    Dashboards.find({ deleted: false })
        .select('name')
        .exec(function (err, dashboards) {
            if (err) {
                console.log(err);
                res.status(500).send(err);
            } else {
                res.send(_.pluck(dashboards, 'name'));
            }
        });
};

exports.get = function (req, res) {

    var search = req.query.q

    if (_.isUndefined(search) || search==='') {
        Dashboards
            .find({ deleted: false })
            .select('-dashboard')
            .exec(_.wrap(res, api.getCallback));    
    }
    else {
        /* Comma-separated search terms */
        var query = Dashboards
            .find({ deleted: false })
            .select('-dashboard')
            .populate('createdBy lastUpdatedBy', 'name')
            .exec(function(err, obj) {
                if (err) {
                    console.log(err);
                    return res.status(500).send(err);
                } else if (_.isUndefined(obj) || _.isNull(obj)) {
                    return res.status(404).send('Dashboard not found.');
                }
                
                /* Comma-separated search terms */
                var searchItems = req.query.q.toLowerCase().split(',');

                /* Create hash of regex objects */
                var searchRegexes = {};
                try {
                    _.each(searchItems, function(item) {
                        searchRegexes[item] = new RegExp(".*" + item + ".*");
                    });
                } catch (e) {
                    /* Bad input, return empty */
                    return res.send([]); 
                }

                var filteredResults = _.filter(obj, function(dashboard) {
                    return _.every(searchItems, function(searchItem) {
                        if (searchRegexes[searchItem].test(dashboard.name))
                            return true;
                        if (_.any(dashboard.tags, function(tag) {
                            return tag.toLowerCase() === searchItem;
                        }))
                            return true;

                        /* No match */
                        return false;
                    });
                });

                res.send(filteredResults);
            });
    }
};

exports.getSingle = function (req, res) {

    var name = req.params.name.toLowerCase();
    Dashboards
        .findOne({ name: name })
        .populate('createdBy lastUpdatedBy', 'sAMAccountName name email')
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

            res.send(dashboard);
        });
};

exports.putPostSingle = function (req, res) {

    if (req.body == null || 
        req.body.dashboard == null) {
        return res.status(400).send('Missing Dashboard.');
    }
    if (req.body.dashboard.name == null || req.body.dashboard.name == '') {
        return res.status(400).send('Missing Dashboard name.');
    }

    /* Standardize name
       This method supports both POST/PUT...so get the dashboard name from the URL, 
       else from the body */
    var name = (req.params.name || req.body.dashboard.name).toLowerCase();

    var dashboard = req.body;
    dashboard.name = dashboard.dashboard.name = name;
    dashboard.description = dashboard.dashboard.description || '';
    dashboard.tags = _.map(req.body.tags || [], function (tag) { return tag.toLowerCase(); });
    dashboard.date = new Date();
    dashboard.deleted = false;
    dashboard.lastUpdatedBy = auth.getUserId(req);
    if (!dashboard.editors) {
        dashboard.editors = [];
    }
    if (!dashboard.viewers) {
        dashboard.viewers = [];
    }

    /* Check if Dashboard exists */
    Dashboards.findOne({ name: name}, function (err, existingDashboard) {
        if (err) {
            res.status(500).send(err);
        } else if (_.isUndefined(existingDashboard) || _.isNull(existingDashboard)) {
            /* Exclude all unexpected and automatic properties */
            dashboard = _.pick(dashboard, ['name', 'deleted', 'date', 'tags', 'description', 'dashboard', 'lastUpdatedBy', 'editors', 'viewers']);
            dashboard.rev = 1;
            dashboard.createdBy = auth.getUserId(req);

            Dashboards.create(dashboard, _.wrap(res, updateCallback));
        } else {
            if (!auth.hasEditPermission(existingDashboard, req)) {
                return res.status(403).send('Edit Permission denied for this Dashboard.');
            }

            Dashboards.findOneAndUpdate({ _id: existingDashboard._id}, {
                $set: {
                    date: dashboard.date,
                    dashboard: dashboard.dashboard,
                    tags: dashboard.tags,
                    description: dashboard.description,
                    lastUpdatedBy: dashboard.lastUpdatedBy,
                    deleted: dashboard.deleted,
                    editors: dashboard.editors,
                    viewers: dashboard.viewers
                },
                $inc: { rev: 1 }
            })
            .populate('createdBy lastUpdatedBy', 'sAMAccountName name email')
            .exec(_.wrap(res, updateCallback));
        }
    });
};

exports.putTagsSingle = function(req, res) {

    var name = req.params.name.toLowerCase();
    var tags = req.body;
    if (!_.isArray(tags)) {
        return res.status(400).send('Tags must be provided as an array of strings.');
    }

    tags = _.map(tags, function (tag) {
        return tag.toLowerCase();
    });

    Dashboards.findOne({ name: name}, function (err, existingDashboard) {
        if (err) {
            res.status(500).send(err);
        } else if (_.isUndefined(existingDashboard) || _.isNull(existingDashboard)) {
            res.status(404).send('Dashboard not found.');
        } else {
            if (!auth.hasEditPermission(existingDashboard, req)) {
                return res.status(403).send('Edit Permission denied for this Dashboard.');
            }

            Dashboards.findOneAndUpdate({ 
                name: name, 
                tags: { $ne: tags }
            }, {
                $set: {
                    date: new Date(),
                    tags: tags,
                    lastUpdatedBy: auth.getUserId(req),
                    deleted: false
                },
                $inc: { rev: 1 }
            })
            .populate('createdBy lastUpdatedBy', 'sAMAccountName name email')
            .exec(_.wrap(res, updateCallback));
        }
    });
};

exports.deleteSingle = function (req, res) {

    if (_.isUndefined(req.params.name)) {
        return res.status(400).send('Missing Dashboard name.');
    }

    var name = req.params.name.toLowerCase();

    Dashboards.findOne({ name: name}, function (err, existingDashboard) {
        if (err) {
            res.status(500).send(err);
        } else if (_.isUndefined(existingDashboard) || _.isNull(existingDashboard)) {
            res.status(404).send('Dashboard not found.');
        } else {
            if (!auth.hasEditPermission(existingDashboard, req)) {
                return res.status(403).send('Edit Permission denied for this Dashboard.');
            }

            Dashboards.findOneAndUpdate({ 
                name: name 
            }, { 
                $set: { 
                    date: new Date(),
                    lastUpdatedBy: auth.getUserId(req),
                    deleted: true
                }, 
                $inc: { rev: 1 }
            })
            .populate('createdBy lastUpdatedBy', 'sAMAccountName name email')
            .exec(_.wrap(res, updateCallback));
        }
    });
};
