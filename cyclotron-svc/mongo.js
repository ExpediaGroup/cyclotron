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

/* Initialize Mongoose */
var _ = require('lodash'),
    mongoose = require('mongoose'),
    Promise = require('bluebird'),
    config = require('./config/config');

/* Connect to Mongo */
console.log('Connecting to: ' + config.mongodb);
mongoose.connect(config.mongodb);

/* Dashboard Schema: Contains the most-recent revision
   of each Dashboard */
var dashboardSchema = mongoose.Schema({
    name          : {type: String, required: true, unique: true},
    rev           : {type: Number, required: true, default: 0},
    deleted       : {type: Boolean, required: true, default: false},
    date          : {type: Date, required: true},
    tags          : {type: []},
    description   : {type: String, required: false},
    dashboard     : {type: mongoose.Schema.Types.Mixed, required: true},
    createdBy     : {type: mongoose.Schema.Types.ObjectId, required: false, ref: 'user'},
    lastUpdatedBy : {type: mongoose.Schema.Types.ObjectId, required: false, ref: 'user'},
    editors       : [{type: mongoose.Schema.Types.Mixed, required: false}],
    viewers       : [{type: mongoose.Schema.Types.Mixed, required: false}],
    pageViews     : {type: Number, required: false, default: 0},
    visits        : {type: Number, required: false, default: 0},
    exports       : {type: Number, required: false, default: 0},
    likes         : [{type: mongoose.Schema.Types.ObjectId, required: false, ref: 'user'}]
});

/* Dashboard Revision Schema: Contains all revisions of all
   Dashboards, including the most recent.  Each revision is
   stored with the author and the created date, along with
   a revision counter */
var revisionSchema = mongoose.Schema({
    name          : {type: String, required: true, unique: false},
    rev           : {type: Number, required: true, default: 0, index: true},
    deleted       : {type: Boolean, required: true, default: false},
    date          : {type: Date, required: true},
    tags          : {type: []},
    description   : {type: String, required: false},
    dashboard     : {type: mongoose.Schema.Types.Mixed, required: true},
    createdBy     : {type: mongoose.Schema.Types.ObjectId, required: false, ref: 'user'},
    lastUpdatedBy : {type: mongoose.Schema.Types.ObjectId, required: false, ref: 'user'},
    editors       : {type: [mongoose.Schema.Types.Mixed], required: false},
    viewers       : {type: [mongoose.Schema.Types.Mixed], required: false}
});

/* User Schema */
var userSchema = mongoose.Schema({
    name               : {type: String, required: true},
    sAMAccountName     : {type: String, required: true, unique: true},
    email              : {type: String, required: true},
    distinguishedName  : {type: String, required: true, unique: true},
    givenName          : {type: String},
    title              : {type: String},
    department         : {type: String},
    division           : {type: String},
    firstLogin         : {type: Date, required: true},
    lastLogin          : {type: Date, required: true},
    timesLoggedIn      : {type: Number, required: true, default: 0},
    memberOf           : {type: [String]},
    admin              : {type: Boolean, required: false},
    emailHash          : {type: String, required: false}
});

/* Session Schema */
var sessionSchema = mongoose.Schema({
    key            : {type: String, required: true, unique: true},
    sAMAccountName : {type: String, required: true},
    user           : {type: mongoose.Schema.Types.ObjectId, required: true, ref: 'user'},
    ipAddress      : {type: String, required: true},
    expiration     : {type: Date, required: true}
});

/* Page Views Analytics Schema: contains records of each Dashboard page view */
var analyticsSchema = mongoose.Schema({
    date         : {type: Date, required: true},
    visitId      : {type: String, required: true},
    uid          : {type: String, required: false},
    user         : {type: mongoose.Schema.Types.ObjectId, required: false, ref: 'user'},
    dashboard    : {type: mongoose.Schema.Types.ObjectId, required: true, ref: 'dashboard2'},
    rev          : {type: Number, required: true},
    page         : {type: Number, required: true},
    parameters   : {type: {}, required: false},
    browser      : {type: {}, required: false},
    ip           : {type: String, required: false},
    widgets      : {type: [String], required: false}
});

/* Data Source Analytics Schema: contains records of completed Data Sources */
var dsAnalyticsSchema = mongoose.Schema({
    date           : {type: Date, required: true},
    visitId        : {type: String, required: true},
    dashboard      : {type: mongoose.Schema.Types.ObjectId, required: true, ref: 'dashboard2'},
    rev            : {type: Number, required: true},
    page           : {type: Number, required: true},
    dataSourceName : {type: String, required: true},
    dataSourceType : {type: String, required: true},
    success        : {type: Boolean, required: true},
    duration       : {type: Number, required: true},
    details        : {type: {}, required: false}
});

/* Event Analytics Schema: contains records of various events */
var eventAnalyticsSchema = mongoose.Schema({
    date           : {type: Date, required: true},
    eventType      : {type: String, required: true},
    visitId        : {type: String, required: true},
    uid            : {type: String, required: false},
    user           : {type: mongoose.Schema.Types.ObjectId, required: false, ref: 'user'},
    details        : {type: {}, required: false}
});

/* Cyclotron Data Schema: contains buckets of data */
var databucketsSchema = mongoose.Schema({
    key              : {type: String, required: true},
    createdDate      : {type: Date, required: true},
    lastModifiedDate : {type: Date, required: true},
    rev              : {type: Number, required: true, default: 0},
    data             : {type: [{}], required: true, default: []}
});

/* Models */

var dashboardModel = mongoose.model('dashboard2', dashboardSchema, 'dashboard2s');
var revisionModel = mongoose.model('revision', revisionSchema);
var userModel = mongoose.model('user', userSchema);
var sessionModel = mongoose.model('session', sessionSchema);
var analyticsModel = mongoose.model('analytics', analyticsSchema);
var dsAnalyticsModel = mongoose.model('dataSourceAnalytics', dsAnalyticsSchema);
var eventAnalyticsModel = mongoose.model('eventAnalytics', eventAnalyticsSchema);
var databucketsModel = mongoose.model('databucket', databucketsSchema);

/* Promisify APIs */
Promise.promisifyAll(userModel);
Promise.promisifyAll(userModel.prototype);
Promise.promisifyAll(sessionModel);
Promise.promisifyAll(sessionModel.prototype);


/* Create Example Dashboards */
/* Create system user */
userModel.findOneAndUpdate({ sAMAccountName: '_cyclotron' }, { 
    $set: {
        name: 'Cyclotron',
        givenName: 'Cyclotron',
        dn: '_cyclotron',
        sAMAccountName: '_cyclotron',
        email: 'cyclotron@cyclotron'
    }
}, { upsert: true, 'new': true }, function (err, user) {
    console.log('Created Cyclotron system user.');
    
    /* Load example Dashboards into Mongo */
    if (config.loadExampleDashboards == true) {
        var fs = require('fs');
        var files = fs.readdirSync(__dirname + '/examples/');
        _(files)
            .filter(function (file) { return file.match(/\.json$/) !== null; })
            .each(function(file) {
                console.log('Loading example: ' + file);
                var name = file.replace('.json', '');
                var dashboard = require('./examples/' + name);

                dashboardModel.findOneAndUpdate({ name: name }, {
                    $set: {
                        name: name,
                        date: new Date(),
                        dashboard: dashboard,
                        tags: ['cyclotron-examples'],
                        description: dashboard.description,
                        lastUpdatedBy: user._id,
                        deleted: false,
                        editors: [user],
                        viewers: [],
                        rev: 1
                    }
                }, { upsert: true }, function (err, dashboard) {
                    revisionModel.remove({ name: name }).exec();
                    console.log('Wrote ' + name);
                });
            });
    }
});


