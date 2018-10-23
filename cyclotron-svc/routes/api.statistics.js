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
 * API for Cyclotron Statistics
 */

var config = require('../config/config'),
    _ = require('lodash'),
    moment = require('moment'),
    mongoose = require('mongoose'),
    Promise = require('bluebird'),
    api = require('./api');
    
var Analytics = mongoose.model('analytics'),
    Dashboards = mongoose.model('dashboard2'),
    DataSourceAnalytics = mongoose.model('dataSourceAnalytics'),
    EventAnalytics = mongoose.model('eventAnalytics'),
    Revisions = mongoose.model('revision'),
    Sessions = mongoose.model('session'),
    Users = mongoose.model('user');

var getDashboardCounts = function () {
    return new Promise(function (resolve, reject) {
        Promise.join(
            getDashboardCounts2(null),
            getDashboardCounts2(true),
            getDashboardCounts2(false),
            getActiveDashboardCounts(),
            function (totalDashboardCounts, deletedDashboardCounts, undeletedDashboardCounts, activeDashboardCounts) {
                resolve({
                    total: totalDashboardCounts,
                    deletedDashboards: deletedDashboardCounts,
                    undeletedDashboards: undeletedDashboardCounts,
                    active: activeDashboardCounts
                });
            })
        .catch(function (err) {
            console.log(err);
            reject(err);
        });
    });
};

var getDashboardCounts2 = function (isDeleted) {
    return new Promise(function (resolve, reject) {
        var oneDay = moment().subtract(1, 'day'),
            thirtyDay = moment().subtract(30, 'day'),
            sixMonths = moment().subtract(6, 'month');

        var pipeline = [{
            $project: {
                editorCount: { $size: { $ifNull: ['$editors', []] } },
                viewerCount: { $size: { $ifNull: ['$viewers', []] } },
                tagsCount: { $size: { $ifNull: ['$tags', []] } },
                editedPastDay: { $cond: [ { '$gt': [ '$date', oneDay.toDate() ] }, 1, 0]},
                editedPastThirtyDay: { $cond: [ { '$gt': [ '$date', thirtyDay.toDate() ] }, 1, 0]},
                editedPastSixMonths: { $cond: [ { '$gt': [ '$date', sixMonths.toDate() ] }, 1, 0]}
            },
        }, {
            $group: {
                _id: {},
                count: { $sum: 1 },
                editedPastDayCount: { $sum: '$editedPastDay' },
                editedPastThirtyDayCount: { $sum: '$editedPastThirtyDay' },
                editedPastSixMonthsCount: { $sum: '$editedPastSixMonths' },
                avgTagsCount: { $avg: '$tagsCount' },
                maxTagsCount: { $max: '$tagsCount' },
                avgEditorCount: { $avg: '$editorCount' },
                avgViewerCount: { $avg: '$viewerCount' },
                unrestrictedEditingCount: { $sum: { $cond: [ { $eq: ['$editorCount', 0] }, 1, 0 ]}},
                unrestrictedViewingCount: { $sum: { $cond: [ { $eq: ['$viewerCount', 0] }, 1, 0 ]}},
                restrictedEditingCount: { $sum: { $cond: [ { $gt: ['$editorCount', 0] }, 1, 0 ]}},
                restrictedViewingCount: { $sum: { $cond: [ { $gt: ['$viewerCount', 0] }, 1, 0 ]}}
            }
        }]

        if (!_.isNull(isDeleted)) {
            pipeline.unshift({
                $match: {
                    deleted: isDeleted
                }
            });
        }

        Dashboards.aggregate(pipeline).exec(function (err, results) {
            if (err) {
                return reject(err);
            }

            resolve(_.omit(results[0], '_id'));
        });
    });
};

var getActiveDashboardCounts = function () {
    return new Promise(function (resolve, reject) {
        var oneDay = moment().subtract(1, 'day'),
            thirtyDay = moment().subtract(30, 'day'),
            sixMonths = moment().subtract(6, 'month');
        
        Analytics.aggregate([{
            $project: {
                dashboard: '$dashboard',
                pastDay: { $cond: [ { '$gt': [ '$date', oneDay.toDate() ] }, 1, 0]},
                pastThirtyDay: { $cond: [ { '$gt': [ '$date', thirtyDay.toDate() ] }, 1, 0]},
                pastSixMonths: { $cond: [ { '$gt': [ '$date', sixMonths.toDate() ] }, 1, 0]}
            },
        }, {
            $group: {
                _id: { 'dashboard': '$dashboard' },
                activePastDay: { $max: '$pastDay' },
                activePastThirtyDay: { $max: '$pastThirtyDay' },
                activePastSixMonths: { $max: '$pastSixMonths' }
            }
        }, {
            $group: {
                _id: { },
                activeDashboards: { $sum: 1 },
                activePastDayCount: { $sum: '$activePastDay' },
                activePastThirtyDayCount: { $sum: '$activePastThirtyDay' },
                activePastSixMonthsCount: { $sum: '$activePastSixMonths' }
            }
        }]).exec(function (err, results) {
            if (err) {
                reject(err);
            }

            results = _.omit(results[0], '_id');
            resolve(results);
        });
    });
};

var getPageViewsCounts = function () {
    return new Promise(function (resolve, reject) {
        Analytics.aggregate([{
            $group: {
                _id: { 'uid': '$uid', 'visitId': '$visitId' },
                totalPageViews: { $sum: 1 },
            }
        }, {
            $group: {
                _id: { 'uid': '$_id.uid' },
                totalPageViews: { $sum: '$totalPageViews'},
                totalVisits: { $sum: 1 }
            }
        }, {
            $group: {
                _id: {},
                totalPageViews: { $sum: '$totalPageViews'},
                totalVisits: { $sum: '$totalVisits'},
                uniqueUids: { $sum: 1 }
            }
        }]).allowDiskUse(true).exec(function (err, results) {
            if (err) {
                reject(err);
            }

            results = _.omit(results[0], '_id');
            results.avgPageViewsPerUid = results.totalPageViews / results.uniqueUids;
            results.avgVisitsPerUid = results.totalVisits / results.uniqueUids;
            results.avgPageViewsPerVisit = results.totalPageViews / results.totalVisits;
            resolve(results);
        });
    });
};

var getUIDCounts = function () {
    return new Promise(function (resolve, reject) {
        var oneDay = moment().subtract(1, 'day'),
            thirtyDay = moment().subtract(30, 'day'),
            sixMonths = moment().subtract(6, 'month');
        
        Analytics.aggregate([{
            $project: {
                uid: '$uid',
                pastDay: { $cond: [ { '$gt': [ '$date', oneDay.toDate() ] }, 1, 0]},
                pastThirtyDay: { $cond: [ { '$gt': [ '$date', thirtyDay.toDate() ] }, 1, 0]},
                pastSixMonths: { $cond: [ { '$gt': [ '$date', sixMonths.toDate() ] }, 1, 0]}
            },
        }, {
            $group: {
                _id: { 'uid': '$uid' },
                activePastDay: { $max: '$pastDay' },
                activePastThirtyDay: { $max: '$pastThirtyDay' },
                activePastSixMonths: { $max: '$pastSixMonths' }
            }
        }, {
            $group: {
                _id: { },
                uidsPastDayCount: { $sum: '$activePastDay' },
                uidsPastThirtyDayCount: { $sum: '$activePastThirtyDay' },
                uidsPastSixMonthsCount: { $sum: '$activePastSixMonths' },
                totalUids: { $sum: 1 }
            }
        }]).exec(function (err, results) {
            if (err) {
                reject(err);
            }

            results = _.omit(results[0], '_id');
            resolve(results);
        });
    });
};

var getUserCounts = function () {
    return new Promise(function (resolve, reject) {
        var oneDay = moment().subtract(1, 'day'),
            thirtyDay = moment().subtract(30, 'day'),
            sixMonths = moment().subtract(6, 'month');

        Users.aggregate([{
            $match: { name: { $ne: 'Cyclotron' } }
        }, {
            $project: {
                timesLoggedIn: '$timesLoggedIn',
                activePastDay: { $cond: [ { '$gt': [ '$lastLogin', oneDay.toDate() ] }, 1, 0]},
                activePastThirtyDay: { $cond: [ { '$gt': [ '$lastLogin', thirtyDay.toDate() ] }, 1, 0]},
                activePastSixMonths: { $cond: [ { '$gt': [ '$lastLogin', sixMonths.toDate() ] }, 1, 0]}
            }
        }, {
            $group: {
                _id: {},
                count: { $sum: 1 },
                activePastDayCount: { $sum: '$activePastDay' },
                activePastThirtyDayCount: { $sum: '$activePastThirtyDay' },
                activePastSixMonthsCount: { $sum: '$activePastSixMonths' },
                avgLoginsPerUser: { $avg: '$timesLoggedIn' }
            }
        }]).exec(function (err, results) {
            if (err) {
                return reject(err);
            }

            resolve(_.omit(results[0], '_id'));
        });
    });
}

/* Aggregates Revisions to determine:
 *   - Number of Revisions
 *   - Average number of Revisions per Dashboards
 */
var getRevisions = function () {
    return new Promise(function (resolve, reject) {
        Revisions.count().exec(function (err, results) {
            if (err) {
                return reject(err);
            }

            resolve({ count: results});
        });
    });
}

/* Aggregates Revisions to determine:
 *   - Number of Users who have edited a Dashboard
 *   - Average number of Dashboards edited per User
 *   - Average number of Revisions created per User
 */
var getUsersByRevisions = function () {
    return new Promise(function (resolve, reject) {
        Revisions.aggregate([{
            $match: { lastUpdatedBy: { $ne: null }}
        }, {
            $project: {
                name: '$name',
                lastUpdatedBy: '$lastUpdatedBy'
            }
        }, {
            $group: {
                _id: { name: '$name', lastUpdatedBy: '$lastUpdatedBy', },
                revisionCount: { $sum: 1 }
            }
        }, {
            $group: {
                _id: { lastUpdatedBy: '$_id.lastUpdatedBy', },
                dashboardCount: { $sum: 1 },
                revisionCount: { $sum: '$revisionCount' }
            }
        }, {
            $group: {
                _id: { },
                avgDashboardsModifiedByUser: { $avg: '$dashboardCount' },
                avgRevisionsByUser: { $avg: '$revisionCount' },
                editingUserCount: { $sum: 1 }
            }
        }]).exec(function (err, results) {
            if (err) {
                return reject(err);
            }

            resolve(_.omit(results[0], '_id'));
        });
    });
}

var getSessionCounts = function () {
    return new Promise(function (resolve, reject) {
        
        Sessions.find({
            expiration: { $gt: moment().toDate() }
        }).count().exec(function (err, results) {
            if (err) {
                console.log(err);
                return reject(err);
            }

            resolve({ activeSessions: results });
        });
    });
}

var getLikes = function () {
    return new Promise(function (resolve, reject) {
        Dashboards.aggregate([{
            $match: {
                deleted: false
            }
        }, {
            $project: {
                likeCount: { $size: { $ifNull: ['$likes', []] } }
            }
        }, {
            $group: {
                _id: {},
                count: { $sum: '$likeCount' }
            }
        }]).exec(function (err, results) {
            if (err) {
                reject(err);
            }

            resolve(_.omit(results[0], '_id'));
        });
    });
}

var getEvents = function (eventType) {
    return new Promise(function (resolve, reject) {
        var oneDay = moment().subtract(1, 'day'),
            oneWeek = moment().subtract(1, 'week'),
            thirtyDay = moment().subtract(30, 'day'),
            sixMonths = moment().subtract(6, 'month');

        pipeline = [{
            $match: { eventType: { $eq: eventType }}
        }, {
            $project: {
                occurredPastDay: { $cond: [ { '$gt': [ '$date', oneDay.toDate() ] }, 1, 0]},
                occurredPastWeek: { $cond: [ { '$gt': [ '$date', oneWeek.toDate() ] }, 1, 0]},
                occurredPastThirtyDay: { $cond: [ { '$gt': [ '$date', thirtyDay.toDate() ] }, 1, 0]},
                occurredPastSixMonths: { $cond: [ { '$gt': [ '$date', sixMonths.toDate() ] }, 1, 0]}
            },
        }, {
            $group: {
                _id: {},
                count: { $sum: 1 },
                occurredPastDayCount: { $sum: '$occurredPastDay' },
                occurredPastWeekCount: { $sum: '$occurredPastWeek' },
                occurredPastThirtyDayCount: { $sum: '$occurredPastThirtyDay' },
                occurredPastSixMonthsCount: { $sum: '$occurredPastSixMonths' }
            }
        }]

        EventAnalytics.aggregate(pipeline).exec(function (err, results) {
            if (err) {
                return reject(err);
            }

            resolve(_.omit(results[0], '_id'));
        });
    });
};

/* General Instance statistics */
exports.get = function (req, res) {

    Promise.join(
        getDashboardCounts(),
        getPageViewsCounts(), 
        getUIDCounts(),
        getUserCounts(),
        getSessionCounts(),
        getUsersByRevisions(),
        getRevisions(),
        getLikes(),
        getEvents('like'),
        getEvents('unlike'),
        function (dashboardCounts, analyticsCounts, uidCounts, userCounts, sessionCounts, usersByRevisions, revisions, likes, likeEvents, unlikeEvents) {

            revisions.avgRevisionCount = revisions.count / dashboardCounts.total.count;

            res.send({
                dashboards: dashboardCounts,
                pageViews: analyticsCounts,
                revisions: revisions,
                sessions: sessionCounts,
                users: _.merge(userCounts, usersByRevisions, uidCounts),
                likes: likes,
                likeEvents: likeEvents,
                unlikeEvents: unlikeEvents
            });
        })
    .catch(function (err) {
        console.log(err);
        res.status(500).send(err);
    });
};
