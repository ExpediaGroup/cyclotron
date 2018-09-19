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

var config = require('./config/config');

var _ = require('lodash'),
    express = require('express'),
    morgan = require('morgan'),
    errorHandler = require('errorhandler'),
    bodyParser = require('body-parser'),
    compression = require('compression'),
    serveStatic = require('serve-static');

var mongo = require('./mongo');

var app = module.exports = express();

app.enable('trust proxy');
app.set('port', process.env.PORT || config.port);

app.use(morgan('combined'));
app.use(compression());

/* Support for non-Unicode charsets (e.g. ISO-8859-1) */
app.use(bodyParser.text({ 
    type: '*/*', 
    limit: (config.requestLimit || '1mb') 
}));

app.use(function(req, res, next) {
    if (req.is('application/json')) {
        req.body = req.body ? JSON.parse(req.body) : {}
    }
    next();
});

/* API Documentation */
app.use(serveStatic(__dirname + '/docs'));

/* Cross-origin requests */
var cors = require('./middleware/cors');
app.use(cors.allowCrossDomain);

/* Optional: Authentication */
if (config.enableAuth == true) {
    /* Custom session management */
    var session = require('./middleware/session');
    app.use(session.sessionLoader);

    /* Passport.js LDAP authentication */
    var passport = require('passport'),
        LdapStrategy = require('passport-ldapauth');

    app.use(passport.initialize());

    passport.use(new LdapStrategy({
        server: {
            url: config.ldap.url,
            bindDn: config.ldap.adminDn,
            bindCredentials: config.ldap.adminPassword,
            searchBase: config.ldap.searchBase,
            searchFilter: config.ldap.searchFilter
        },
        usernameField: 'username',
        passwordField: 'password'
    }));
}

/* Optional: Analytics */
if (config.analytics && config.analytics.enable == true) {
    if (config.analytics.analyticsEngine == 'elasticsearch') {
        /* Initialize Elasticsearch for Analytics */
        var elasticsearch = require('./elastic');
    }
}

/* Initialize SSL root CAs */
var cas = require('ssl-root-cas/latest')
  .inject();

/* Optional: Load Additional Trusted Certificate Authorities */
if (_.isArray(config.trustedCa) && !_.isEmpty(config.trustedCa)) {
    _.each(config.trustedCa, function(ca) {
        console.log('Loading trusted CA: ' + ca);
        cas.addFile(ca);
    });
}

if ('development' == app.get('env')) {
  app.use(errorHandler());
}

/* Initialize JSON API */
var api = require('./routes/api');
api.bindRoutes(app);

/* Start server */
var port = app.get('port');
app.listen(port, function(){
    console.log('Cyclotron running on port %d', port);
});
