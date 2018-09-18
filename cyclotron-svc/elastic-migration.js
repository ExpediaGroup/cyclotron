/*
 * Copyright (c) 2016-2018 the original author or authors.
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
  * Helper script to migrate Analytics data from MongoDB to Elasticsearch. 
  *
  * Intended to be run manually
  * Uses the same config/config.js file to connect to both MongoDB and Elasticsearch
  * Should be run after the Cyclotron-svc has run and initialized the Index Templates
  *
  */

var mongoose = require('mongoose'),
    Promise = require('bluebird'),
    _ = require('lodash'), 
    highland = require('highland');

var mongo = require('./mongo');
var PageViewAnalytics = mongoose.model('analytics'),
    DataSourceAnalytics = mongoose.model('dataSourceAnalytics'),
    EventAnalytics = mongoose.model('eventAnalytics'),
    Dashboards = mongoose.model('dashboard2'),
    Users = mongoose.model('user');

var elasticsearch = require('./elastic');

var dashboardCache = {},
    userCache = {};

/* Use filters to limit or partition the migrated data */
var migrationFilters = { date: {
    $gte: new Date('2016-01-01T00:00:00.000Z'),
    $lte: new Date('2016-09-01T00:00:00.000Z')
}};

/* Generic function for all 3 types of analytics */
var migrateAnalytics = function (mongoCollection, filters, docType, indexStrategy) {

    console.log('Migrating Analytics: ' + docType);
    return new Promise(function (resolve, reject) {
        /* Get expected count */
        mongoCollection.count(filters).exec(function (err, result) {
            if (err) {
                console.error('Error getting count from MongoDB: ');
                console.error(err);
                return reject();
            }

            var expectedDocumentCount = result;
            console.log('Expected document count: ' + result);

            /* Event Analytics */
            var done = false;
            var documentCount = 0;
            var errors = 0;
            var startTime = new Date().getTime();
            var stream = mongoCollection.find(filters)
                .lean()
                .stream();

            var finished = function () {
                /* Check for completion */
                if (documentCount >= expectedDocumentCount) {
                    console.log('Final Document Count is: ' + documentCount);
                    console.log('Duration is: ' + (new Date().getTime() - startTime));
                    console.log('Number of errors: ' + errors);
                    resolve();
                } else {
                    console.log('Current: ' + documentCount + '; Expected: ' + expectedDocumentCount);
                }
            }

            highland(stream)
                .batchWithTimeOrCount(199, 500)
                .ratelimit(1, 200)
                .each(function (batch) {
                    console.log('  < Processing batch of ' + batch.length);

                    var bulk = [];
                    _.each(batch, function (doc) {
                        /* Lookup user name and dashboard name */
                        if (doc.user) {
                            doc.user = { _id: doc.user, name: userCache[doc.user] };
                        }
                        if (doc.dashboard) {
                            doc.dashboard = { _id: doc.dashboard, name: dashboardCache[doc.dashboard] };
                        }

                        /* Update Widgets schema */
                        if (doc.widgets) {
                            doc.widgets = _.map(doc.widgets, function (widgetName) {
                                return { name: widgetName };
                            });
                        }

                        if (doc.details && _.isString(doc.details.errorMessage) && doc.details.errorMessage.length > 4000) {
                            doc.details.errorMessage = doc.details.errorMessage.substr(0,4000);
                        }

                        bulk.push({ index: { _index: indexStrategy(doc.date), _type: docType, _id: doc._id }});

                        delete doc._id;
                        delete doc.__v;
                        bulk.push(doc);
                    })
                    
                    elasticsearch.client.bulk({
                        body: bulk
                    }, function (err, resp) {
                        documentCount += batch.length;

                        if (err) {
                            console.error('Bulk Error: ');
                            console.error(err);
                            errors++;
                        } else {
                            if (resp.errors == true) {
                                console.log(JSON.stringify(resp));
                                errors++;
                            }
                            
                            console.log('  > Sent ' + batch.length + ' documents to Elasticsearch!');
                        }

                        finished();
                    });
                }).done(function () {
                    finished();
                });
        });
    });
};

/* Cache dashboards/users for populating names from IDs...
 * This is faster than mongoose's populate() */
console.log('Initializing Dashboard/User cache');
Dashboards.find({}).exec(function (err, dashboards) {
    if (err) {
        return console.error(err);
    }

    _.each(dashboards, function (dashboard) {
        dashboardCache[dashboard._id] = dashboard.name;
    });

    Users.find({}).exec(function (err, users) {
        if (err) {
            return console.error(err);
        }

        _.each(users, function (user) {
            userCache[user._id] = user.name;
        });

        /* Start migration */
        console.log('Starting Migration...');
        console.log('---- Page Views ----');
        migrateAnalytics(PageViewAnalytics, migrationFilters, 'pageview', elasticsearch.pageviewsIndexStrategy).then(function() {
            console.log('---- DataSources ----');
            migrateAnalytics(DataSourceAnalytics, migrationFilters, 'datasource', elasticsearch.datasourcesIndexStrategy).then(function() {
                console.log('---- Events ----');
                migrateAnalytics(EventAnalytics, migrationFilters, 'event', elasticsearch.eventsIndexStrategy).then(function() {
                    process.exit();
                });
            });
        });
    });

});
