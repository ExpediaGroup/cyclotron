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

var _ = require('lodash'),
    config = require('../config/config');

var auth = require('./auth.js'),
    crypto = require('./api.crypto.js'),
    dashboards = require('./api.dashboards.js'),
    data = require('./api.data.js'),
    exporter = require('./api.exports.js'),
    ldap = require('./api.ldap.js'),
    proxy = require('./api.proxy.js'),
    revisions = require('./api.revisions.js'),
    tags = require('./api.tags.js'),
    users = require('./api.users.js');

var notAllowed = function (req, res) {
    res.status(405).send('Not Allowed');
};

var requiresAuth = function (req, res, next) {
    if (auth.isUnauthenticated(req)) {
        return res.status(401).send('Authentication required: session key not provided.');
    } else {
        next();
    }
};

/* General purpose callback for outputting models */
exports.getCallback = function (res, err, obj) {
    if (err) {
        console.log(err);
        res.status(500).send(err);
    } else if (_.isUndefined(obj) || _.isNull(obj)) 
        res.status(404).send('Not found');
    else {
        res.send(obj);
    }
};

exports.bindRoutes = function (app) {

    /* Dashboards Types */
    app.get('/dashboards', dashboards.get);
    app.post('/dashboards', requiresAuth, dashboards.putPostSingle);
    app.all('/dashboards', notAllowed);

    app.get('/dashboards/:name', dashboards.getSingle);
    app.post('/dashboards/:name', notAllowed);
    app.put('/dashboards/:name', requiresAuth, dashboards.putPostSingle);
    app.delete('/dashboards/:name', requiresAuth, dashboards.deleteSingle);

    app.put('/dashboards/:name/tags', requiresAuth, dashboards.putTagsSingle);
    app.all('/dashboards/:name/tags', notAllowed);

    app.get('/dashboards/:name/revisions', revisions.get);
    app.all('/dashboards/:name/revisions', notAllowed);
    
    app.get('/dashboards/:name/revisions/:rev', revisions.getSingle);
    app.all('/dashboards/:name/revisions/:rev', notAllowed);
    app.get('/dashboards/:name/revisions/:rev/diff/:rev2', revisions.diff);

    app.get('/dashboards/:name/likes', dashboards.getLikes);
    app.post('/dashboards/:name/likes', requiresAuth, dashboards.likeDashboard);
    app.delete('/dashboards/:name/likes', requiresAuth, dashboards.unlikeDashboard);
    app.all('/dashboards/:name/likes', notAllowed);

    app.get('/dashboardnames', dashboards.getNames);
    app.all('/dashboardnames', notAllowed);

    app.get('/tags', tags.get);
    app.all('/tags', notAllowed);

    app.get('/searchhints', tags.getSearchHints);
    app.all('/searchhints', notAllowed);

    app.post('/export/data', exporter.dataAsync);
    app.get('/export/:name/pdf', exporter.pdf);
    app.post('/export/:name/pdf', exporter.pdfAsync);
    app.all('/export/:name/pdf', notAllowed);
    app.all('/export', notAllowed);

    app.all('/exportstatus/:key', exporter.status);

    app.get('/exports/:file', exporter.serve);

    app.post('/proxy', proxy.proxy);

    app.get('/users', users.get);
    app.get('/users/:name', users.getSingle);

    app.post('/users/login', users.login);
    app.all('/users/login', notAllowed);
    app.post('/users/validate', users.validate);
    app.all('/users/validate', notAllowed);
    app.all('/users/logout', users.logout);

    app.get('/ldap/search', ldap.search);

    app.get('/crypto/ciphers', crypto.ciphers);
    app.post('/crypto/encrypt', crypto.encrypt);
    app.all('/crypto/*', notAllowed);

    /* Enable analytics via Config */
    if (config.analytics && config.analytics.enable == true) {
        var analytics = null;
        var statistics = null;
        
        /* Load Analytics backend: Elasticsearch or MongoDB (default) */
        if (config.analytics.analyticsEngine == 'elasticsearch') {
            analytics = require('./api.analytics-elasticsearch.js');
            statistics = require('./api.statistics-elasticsearch.js');
        } else {
            analytics = require('./api.analytics.js');
            statistics = require('./api.statistics.js');
        }

        app.get('/statistics', statistics.get);
    
        app.post('/analytics/pageviews', analytics.recordPageView);
        app.get('/analytics/pageviews/recent', analytics.getRecentPageViews);

        app.post('/analytics/datasources', analytics.recordDataSource);
        app.get('/analytics/datasources/recent', analytics.getRecentDataSources);

        app.post('/analytics/events', analytics.recordEvent);
        app.get('/analytics/events/recent', analytics.getRecentEvents);

        app.get('/analytics/pageviewsovertime', analytics.getPageViewsOverTime);
        app.get('/analytics/visitsovertime', analytics.getVisitsOverTime);
        app.get('/analytics/uniquevisitors', analytics.getUniqueVisitors);
        app.get('/analytics/browsers', analytics.getBrowserStats);
        app.get('/analytics/widgets', analytics.getWidgetStats);

        app.get('/analytics/datasourcesbytype', analytics.getDataSourcesByType);
        app.get('/analytics/datasourcesbyname', analytics.getDataSourcesByName);
        app.get('/analytics/datasourcesbyerrormessage', analytics.getDataSourcesByErrorMessage);

        app.get('/analytics/pageviewsbypage', analytics.getPageViewsByPage);

        app.get('/analytics/topdashboards', analytics.getTopDashboards);

        app.get('/analytics/delete', analytics.deleteAnalyticsForDashboard);
    }
    app.all('/analytics', notAllowed);
    app.all('/analytics/*', notAllowed);

    app.get('/data', data.get);
    app.post('/data', data.putPostSingle);
    app.all('/data', notAllowed);

    app.get('/data/:key', data.getSingle);
    app.post('/data/:key', notAllowed);
    app.put('/data/:key', data.putPostSingle);
    app.delete('/data/:key', data.deleteSingle);

    app.get('/data/:key/data', data.getSingleData);
    app.put('/data/:key/data', data.putData);
    app.post('/data/:key/append', data.appendData);
    app.post('/data/:key/upsert', data.upsertData);
    app.post('/data/:key/remove', data.removeData);
};
