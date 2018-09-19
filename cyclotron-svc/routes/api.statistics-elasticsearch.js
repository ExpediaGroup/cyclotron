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
 * API for Cyclotron Statistics - Elasticsearch implementation
 * (only analytics data is pulled from Elasticsearch)
 */

var config = require('../config/config'),
    _ = require('lodash'),
    moment = require('moment'),
    mongoose = require('mongoose'),
    Promise = require('bluebird'),
    api = require('./api');
    
var Dashboards = mongoose.model('dashboard2'),
    Revisions = mongoose.model('revision'),
    Sessions = mongoose.model('session'),
    Users = mongoose.model('user');

var elasticsearch = require('../elastic');

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
        elasticsearch.client.search({
            index: elasticsearch.indexAlias('pageviews'),
            body: {
                size: 0,
                query: { match_all: {} },
                aggs: {
                    activeDashboards: {
                        cardinality: {
                            field: 'dashboard._id',
                            precision_threshold: 100
                        }
                    },
                    occurredPastDay: {
                        filter: { range: { date: { gte: 'now-1d' } } },
                        aggs: {
                            activeDashboards: {
                                cardinality: {
                                    field: 'dashboard._id',
                                    precision_threshold: 100
                                }
                            }
                        }
                    },
                    occurredPastThirtyDay: {
                        filter: { range: { date: { gte: 'now-30d' } } },
                        aggs: {
                            activeDashboards: {
                                cardinality: {
                                    field: 'dashboard._id',
                                    precision_threshold: 100
                                }
                            }
                        }
                    },
                    occurredPastSixMonths: {
                        filter: { range: { date: { gte: 'now-6M' } } },
                        aggs: {
                            activeDashboards: {
                                cardinality: {
                                    field: 'dashboard._id',
                                    precision_threshold: 100
                                }
                            }
                        }
                    }
                }
            }
        }).then(function (response) {
            var results = {
                activeDashboards: response.aggregations.activeDashboards.value,
                activePastDayCount: response.aggregations.occurredPastDay.activeDashboards.value,
                activePastThirtyDayCount: response.aggregations.occurredPastThirtyDay.activeDashboards.value,
                activePastSixMonthsCount: response.aggregations.occurredPastSixMonths.activeDashboards.value
            };
            resolve(results);
        }).catch(function (err) {
            reject(err);
        });
    });
};

var getPageViewsCounts = function () {
    return new Promise(function (resolve, reject) {
        elasticsearch.client.search({
            index: elasticsearch.indexAlias('pageviews'),
            body: {
                    size: 0,
                    query: { match_all: {} },
                    aggs: {
                        distinctVisits: {
                            cardinality: {
                                field: 'visitId',
                                precision_threshold: 100
                            }
                        },
                        uniqueUids: {
                            cardinality: {
                                field: 'uid',
                                precision_threshold: 100
                            }
                        }
                    }
                }
        }).then(function (response) {
            var results = {
                totalPageViews: response.hits.total,
                totalVisits: response.aggregations.distinctVisits.value,
                uniqueUids: response.aggregations.uniqueUids.value,
                avgPageViewsPerUid: response.hits.total / response.aggregations.uniqueUids.value,
                avgVisitsPerUid: response.aggregations.distinctVisits.value / response.aggregations.uniqueUids.value,
                avgPageViewsPerVisit: response.hits.total / response.aggregations.distinctVisits.value
            };
            resolve(results);
        }).catch(function (err) {
            reject(err);
        });
    });
};

var getUIDCounts = function () {
    return new Promise(function (resolve, reject) {
        
        elasticsearch.client.search({
            index: elasticsearch.indexAlias('pageviews'),
            body: {
                size: 0,
                query: { match_all: {} },
                aggs: {
                    uniqueUids: {
                        cardinality: {
                            field: 'uid',
                            precision_threshold: 100
                        }
                    },
                    occurredPastDay: {
                        filter: {  range: { date: { gte: 'now-1d' } } },
                        aggs: {
                            uniqueUids: {
                                cardinality: {
                                    field: 'uid',
                                    precision_threshold: 100
                                }
                            }
                        }
                    },
                    occurredPastThirtyDay: {
                        filter: {  range: { date: { gte: 'now-30d' } } },
                        aggs: {
                            uniqueUids: {
                                cardinality: {
                                    field: 'uid',
                                    precision_threshold: 100
                                }
                            }
                        }
                    },
                    occurredPastSixMonths: {
                        filter: {  range: { date: { gte: 'now-6M' } } },
                        aggs: {
                            uniqueUids: {
                                cardinality: {
                                    field: 'uid',
                                    precision_threshold: 100
                                }
                            }
                        }
                    }
                }
            }
        }).then(function (response) {
            var results = {
                totalUids: response.aggregations.uniqueUids.value,
                uidsPastDayCount: response.aggregations.occurredPastDay.uniqueUids.value,
                uidsPastThirtyDayCount: response.aggregations.occurredPastThirtyDay.uniqueUids.value,
                uidsPastSixMonthsCount: response.aggregations.occurredPastSixMonths.uniqueUids.value
            };
            resolve(results);
        }).catch(function (err) {
            reject(err);
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

        elasticsearch.client.search({
            index: elasticsearch.indexAlias('events'),
            body: {
                    size: 0,
                    query: { term: { eventType: eventType } },
                    aggs: {
                        occurredPastHour: {
                            filter: {  range: { date: { gte: 'now-1h' } } }
                        },
                        occurredPastDay: {
                            filter: {  range: { date: { gte: 'now-1d' } } }
                        },
                        occurredPastWeek: {
                            filter: {  range: { date: { gte: 'now-1w' } } }
                        },
                        occurredPastThirtyDayCount: {
                            filter: {  range: { date: { gte: 'now-30d' } } }
                        },
                        occurredPastSixMonths: {
                            filter: {  range: { date: { gte: 'now-6M' } } }
                        }
                    }
                }
        }).then(function (response) {
            var results = {
                count: response.hits.total,
                occurredPastHourCount: response.aggregations.occurredPastHour.doc_count,
                occurredPastDayCount: response.aggregations.occurredPastDay.doc_count,
                occurredPastWeekCount: response.aggregations.occurredPastWeek.doc_count,
                occurredPastThirtyDayCount: response.aggregations.occurredPastThirtyDayCount.doc_count,
                occurredPastSixMonthsCount: response.aggregations.occurredPastSixMonths.doc_count
            };
            resolve(results);
        }).catch(function (err) {
            reject(err);
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
        getRevisions(),
        getLikes(),
        getEvents('like'),
        getEvents('unlike'),
        function (dashboardCounts, analyticsCounts, uidCounts, userCounts, sessionCounts, revisions, likes, likeEvents, unlikeEvents) {

            revisions.avgRevisionCount = revisions.count / dashboardCounts.total.count;

            res.send({
                dashboards: dashboardCounts,
                pageViews: analyticsCounts,
                revisions: revisions,
                sessions: sessionCounts,
                users: _.merge(userCounts, uidCounts),
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
