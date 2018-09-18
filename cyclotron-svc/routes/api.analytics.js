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
 * API for Analytics
 */

var config = require('../config/config'),
    _ = require('lodash'),
    moment = require('moment'),
    mongoose = require('mongoose'),
    Promise = require('bluebird'),
    api = require('./api'),
    auth = require('./auth');
    
var Analytics = mongoose.model('analytics'),
    DataSourceAnalytics = mongoose.model('dataSourceAnalytics'),
    EventAnalytics = mongoose.model('eventAnalytics'),
    Dashboards = mongoose.model('dashboard2');

/* Log a Dashboard visit & Page view
 *
 * New visits are incremented with ?newVisit=true 
 * Exports are incremented with &exporting=true&newVisit=true
 */
exports.recordPageView = function (req, res) {
    /* Defaults */
    var record = req.body;
    record.date = new Date();
    record.ip = req.ip;

    if (record.dashboard == null) {
        return res.status(400).send('Missing Dashboard name.');
    } else if (record.visitId == null) {
        return res.status(400).send('Missing Visit ID.');
    } else if (record.user == null && record.uid == null) {
        return res.status(400).send('Missing User or UID.');
    } else if (record.page == null) {
        return res.status(400).send('Missing page number.');
    } else if (record.rev == null) {
        return res.status(400).send('Missing revision number.');
    }

    /* Send 200 OK as soon as possible */
    res.send();

    if (!_.isNull(record.dashboard)) {
        record.dashboard = new mongoose.Types.ObjectId(record.dashboard._id);
    }
    if (!_.isNull(record.user)) {
        record.user = new mongoose.Types.ObjectId(record.user._id);
    }

    var pageViewInc = 0, 
        visitInc = 0, 
        exportInc = 0;

    /* Exporting a dashboard does not create an Analytics record, 
     * nor increment pageViews/visits */
    if (req.query.exporting == 'true') {
        /* Only increment export counter once per visit */
        if (req.query.newVisit == 'true') {
            exportInc = 1;
        }
    } else {
        /* Create new record in the Analytics collection */
        var analytic = new Analytics(record);
        analytic.save();

        pageViewInc = 1;

        /* Increment counters on the Dashboard document */
        if (req.query.newVisit == 'true') {
            visitInc = 1;
        }
    }

    /* Increment counters on Dashboard */
    Dashboards.findOneAndUpdate({ _id: record.dashboard}, {
        $inc: { 
            pageViews: pageViewInc,
            visits: visitInc,
            exports: exportInc
        }
    }).exec();
};

/* Log a Data Source execution */
exports.recordDataSource = function (req, res) {
    /* Defaults */
    var record = req.body;
    record.date = new Date();

    if (record.dashboard == null) {
        return res.status(400).send('Missing Dashboard name.');
    } else if (record.visitId == null) {
        return res.status(400).send('Missing Visit ID.');
    } else if (record.dataSourceName == null || record.dataSourceType == null) {
        return res.status(400).send('Missing Data Source Name or Type.');
    } else if (record.success == null) {
        return res.status(400).send('Missing sucess.');
    } else if (record.duration == null) {
        return res.status(400).send('Missing duration.');
    }

    /* Send 200 OK as soon as possible */
    res.send();

    if (!_.isNull(record.dashboard)) {
        record.dashboard = new mongoose.Types.ObjectId(record.dashboard._id);
    }

    /* Create new record in the Data Source Analytics collection */
    var analytic = new DataSourceAnalytics(record);
    analytic.save();
};

/* Log an Event*/
exports.recordEvent = function (req, res) {
    
    /* Defaults */
    var record = req.body;
    record.date = new Date();

    if (record.eventType == null) {
        return res.status(400).send('Missing Event type.');
    } else if (record.visitId == null) {
        return res.status(400).send('Missing Visit ID.');
    } else if (record.user == null && record.uid == null) {
        return res.status(400).send('Missing User or UID.');
    }

    /* Send 200 OK as soon as possible */
    res.send();

    if (!_.isNull(record.user)) {
        record.user = new mongoose.Types.ObjectId(record.user._id);
    }

    /* Create new record in the Event Analytics collection */
    var analytic = new EventAnalytics(record);
    analytic.save();
};

exports.deleteAnalyticsForDashboard = function (req, res) {

    if (!auth.isAdmin(req)) {
        return res.status(403).send('Permission denied.');
    }

    var dashboardId = req.query.dashboard;

    if (_.isUndefined(dashboardId)) {
        return res.status(400).send('Missing Dashboard ID.');
    }

    var dashboardObjectId = new mongoose.Types.ObjectId(dashboardId);
    Analytics.remove({ dashboard: dashboardObjectId }, function (err) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        DataSourceAnalytics.remove({ dashboard: dashboardObjectId }, function (err) {
            if (err) {
                console.log(err);
                return res.status(500).send(err);
            }

            Dashboards.findOneAndUpdate( { _id: dashboardObjectId }, 
            {
                pageViews: 0,
                visits: 0,
                exports: 0
            }, function (err) {
                if (err) {
                    console.log(err);
                    return res.status(500).send(err);
                }
                
                res.send('OK');
            })
        });
    });
};

/* Gets 100 most-recent Page View analytics records */
exports.getRecentPageViews = function (req, res) {
    var query = null;

    if (_.isUndefined(req.query.dashboard)) {
        query = Analytics.find();
    } else {
        query = Analytics.find({ dashboard: new mongoose.Types.ObjectId(req.query.dashboard) });
    }

    query.sort('-date')
        .limit(req.query.max || 100)
        .populate('dashboard', 'name')
        .populate('user', 'sAMAccountName')
        .exec(_.wrap(res, api.getCallback));
};

/* Gets 100 most-recent Data Source analytics records */
exports.getRecentDataSources = function (req, res) {
    var query = null;
    if (_.isUndefined(req.query.dashboard)) {
        query = DataSourceAnalytics.find();
    } else {
        query = DataSourceAnalytics.find({ dashboard: new mongoose.Types.ObjectId(req.query.dashboard) });
    }

    query.sort('-date')
        .limit(req.query.max || 100)
        .populate('dashboard', 'name')
        .exec(_.wrap(res, api.getCallback));
};

/* Gets 100 most-recent Event analytics records */
exports.getRecentEvents = function (req, res) {
    var query = null;
    if (_.isUndefined(req.query.type)) {
        query = EventAnalytics.find();
    } else {
        query = EventAnalytics.find({ type: req.query.type });
    }

    query.sort('-date')
        .limit(req.query.max || 100)
        .exec(_.wrap(res, api.getCallback));
};

/* Gets 100 most-visited Dashboards */
exports.getTopDashboards = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);
    var max = parseInt(req.query.max);

    /* Define match step with start and end dates */
    var pipeline = getMatchingPipeline(filters);

    /* Create pipeline */
    pipeline = pipeline.concat({
        $group: {
            _id: '$dashboard',
            pageViews: { $sum: 1 }
        }
    }, {
        $sort: { pageViews: -1 }
    }, {
        $limit: max || 100
    });

    Analytics.aggregate(pipeline).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        Dashboards.populate(results, { 
            path: '_id', 
            select: '-dashboard -editors -viewers'
        }, function (err, populatedResults) {
            if (err) {
                console.log(err);
                return reject(err);
            }

            res.send(_.compact(_.map(populatedResults, function(result) {
                return result._id;
            })));
        });
    });
};

/* Create a filters object */
var getFilters = function (startDate, endDate, dashboardId, resolution) {

    var filters = {
        resolution: 'minute'
    };

    if (!_.isUndefined(dashboardId)) {
        filters.dashboardId = dashboardId;
    }

    if (!_.isUndefined(resolution)) {
        filters.resolution = resolution;
    }

    /* Convert to Moment date, adjust to resolution */
    if (!_.isUndefined(startDate)) {
        if (_.isString(startDate)) {
            startDate = moment(startDate).utc();
        }
        filters.startDate = startDate.startOf(filters.resolution);
    }

    if (!_.isUndefined(endDate)) {
        if (_.isString(endDate)) {
            endDate = moment(endDate).utc();
        }

        filters.endDate = endDate.endOf(filters.resolution);
    }

    return filters;
};

/* Create a filters object, with default start/end dates */
var getFiltersWithDefaultDates = function (startDate, endDate, dashboardId, resolution) {

    if (_.isUndefined(startDate)) {
        startDate = moment().utc().subtract(1, 'day');
    }

    if (_.isUndefined(endDate)) {
        endDate = moment().utc();
    }

    return getFilters(startDate, endDate, dashboardId, resolution);
};

/* Create an Aggregation pipeline with a match step */
var getMatchingPipeline = function (filters) {

    var pipelineMatch = {};

    /* Start Date filter */
    if (!_.isUndefined(filters.startDate)) {
        pipelineMatch.$match = {
            date: { 
                $gte: filters.startDate.toDate()
            }
        }
    }

    /* End Date filter */
    if (!_.isUndefined(filters.endDate)) {
        if (_.isUndefined(pipelineMatch.$match)) {
            pipelineMatch.$match = { date: {} };
        }
        
        pipelineMatch.$match.date.$lte = filters.endDate.toDate();
    }

    /* Dashboard filter */
    if (!_.isUndefined(filters.dashboardId)) {
        if (_.isUndefined(pipelineMatch.$match)) {
            pipelineMatch.$match = {}
        }

        pipelineMatch['$match'].dashboard = new mongoose.Types.ObjectId(filters.dashboardId);
    }

    /* Return empty pipeline, or pipeline with match step */
    if (_.isEmpty(pipelineMatch)) {
        return [];
    } else {
        return [pipelineMatch];
    }
};

var getFirstDateGrouping = function (resolution) {
    var grouping = { 
        year: { $year: '$date' },
        month: { $month: '$date' },
        day: { $dayOfMonth: '$date' }
    };

    if (resolution == 'hour' || resolution == 'minute') {
        grouping.hour = { $hour: '$date' };

        if (resolution == 'minute') {
            grouping.minute = { $minute: '$date' };
        }
    }

    return grouping;
}

var getSecondDateGrouping = function (resolution) {
    var grouping = {
        year: '$_id.year',
        month: '$_id.month',
        day: '$_id.day'
    };

    if (resolution == 'hour' || resolution == 'minute') {
        grouping.hour = '$_id.hour';

        if (resolution == 'minute') {
            grouping.minute = '$_id.minute';
        }
    }

    return grouping;
};

var executeTimePipeline = function (filters, pipeline, field, res) {
    Analytics.aggregate(pipeline).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        var rawData = _.map(results, function (result) {

            /* Recreate date object from parts */
            result.date = moment.utc({ 
                    years: result._id.year, 
                    months: result._id.month - 1, 
                    day: result._id.day
                });

            if (result._id.hour) {
                result.date.hour(result._id.hour);
            }
            if (result._id.minute) {
                result.date.minute(result._id.minute);
            }

            delete result._id;

            return result;
        });

        if (!_.isUndefined(filters.startDate)) {
            /* Generate missing rows with 0 value */
            var combinedResults = [];
            var startDate = filters.startDate,
                endDate = filters.endDate;

            while (!endDate.isBefore(startDate)) {
                var currentRow = _.find(rawData, function (row) {
                    return startDate.isSame(row.date);
                });

                if (currentRow == null) {
                    currentRow = {};
                    currentRow[field] = 0;
                    currentRow.date = startDate.clone();
                }

                combinedResults.push(currentRow);
                startDate.add(1, filters.resolution);
            }

            return res.send(combinedResults);
        } else {
            return res.send(rawData);
        }
    });
};

/* Gets all page views over time, grouped by minute */
exports.getPageViewsOverTime = function (req, res) {

    if (!_.isUndefined(req.query.resolution)) {
        if (req.query.resolution != 'day' && req.query.resolution != 'hour' && req.query.resolution != 'minute') {
            return res.status(400).send('Invalid resolution (day, hour, minute).');
        }
    }

    var filters = getFiltersWithDefaultDates(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    /* Define pipeline with match step with start and end dates */
    var pipeline = getMatchingPipeline(filters);

    /* Create pipeline */
    pipeline = pipeline.concat({
        $group: {
            _id: getFirstDateGrouping(filters.resolution),
            pageViews: { $sum: 1 }
        }
    }, {
        $sort: { _id: 1 }
    });

    executeTimePipeline(filters, pipeline, 'pageViews', res);
};

/* Gets all visits over time, grouped by minute */
exports.getVisitsOverTime = function (req, res) {
    
    if (!_.isUndefined(req.query.resolution)) {
        if (req.query.resolution != 'day' && req.query.resolution != 'hour' && req.query.resolution != 'minute') {
            return res.status(400).send('Invalid resolution (day, hour, minute).');
        }
    }

    var filters = getFiltersWithDefaultDates(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    /* Define pipeline with match step with start and end dates */
    var pipeline = getMatchingPipeline(filters);

    var firstGroup = getFirstDateGrouping(filters.resolution);
    firstGroup.visitId = '$visitId';

    var secondGroup = getSecondDateGrouping(filters.resolution);

    /* Create pipeline */
    pipeline = pipeline.concat({
        $group: {
            _id: firstGroup
        }
    }, { 
        $group: {
            _id: secondGroup,
            visits: { $sum: 1 }
        }
    }, {
        $sort: { _id: 1 }
    });

    executeTimePipeline(filters, pipeline, 'visits', res);
};

/* Gets unique visitors */
exports.getUniqueVisitors = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    /* Define pipeline with match step with start and end dates */
    var pipeline = getMatchingPipeline(filters);

    /* Create pipeline */
    var anonymousPipeline = pipeline.concat({
        $match: { user: null}
    }, {
        $group: {
            _id: '$uid',
            ip: { $first: '$ip' },
            pageViews: { $sum: 1 }
        }
    }, {
        $sort: { pageViews: -1 }
    });

    var authPipeline = pipeline.concat({
        $match: { user: { $ne: null } }
    }, {
        $group: {
            _id: { user: '$user' },
            pageViews: { $sum: 1 }
        }
    }, {
        $sort: { pageViews: -1 }
    });

    var max = parseInt(req.query.max);
    if (max != 0) {
        anonymousPipeline.push({
            $limit: max || 100
        });
        authPipeline.push({
            $limit: max || 100
        });
    }

    var anonymousPromise = new Promise(function (resolve, reject) {
        Analytics.aggregate(anonymousPipeline).exec(function (err, results) {
            if (err) {
                console.log(err);
                return reject(err);
            }

            results = _.map(results, function (row) {
                return { 
                    uid: row._id,
                    ip: row.ip,
                    pageViews: row.pageViews
                };
            });

            resolve(results);
        });
    });

    var authPromise = new Promise(function (resolve, reject) {
        Analytics.aggregate(authPipeline).exec(function (err, results) {
            if (err) {
                console.log(err);
                reject(err);
            }

            results = _.map(results, function (row) {
                return { 
                    user: row._id.user,
                    pageViews: row.pageViews
                };
            });
            Analytics.populate(results, { path: 'user' }, function (err, populatedResults) {
                if (err) {
                    console.log(err);
                    return reject(err);
                }

                resolve(populatedResults);
            });
        });
    });

    Promise.join(anonymousPromise, authPromise,
        function (anonymousUsers, authenticatedUsers) {
            var results = _.sortBy(_.union(anonymousUsers, authenticatedUsers), 'pageViews').reverse();

            /* Limit results */
            if (!_.isNull(max) && max > 0) {
                results = _.take(results, max);
            }

            res.send(results);
        })
    .catch(function (err) {
        return res.status(500).send(err);
    });    
};

/* Gets browser statistics */
exports.getBrowserStats = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    /* Define match step with start and end dates */
    var pipeline = getMatchingPipeline(filters);

    /* Create pipeline */
    pipeline = pipeline.concat({
        $group: {
            _id: '$browser',
            pageViews: { $sum: 1 }
        }
    }, {
        $sort: { pageViews: -1 }
    });

    var max = parseInt(req.query.max);
    if (max != 0) {
        pipeline.push({ $limit: max || 100 });
    }

    Analytics.aggregate(pipeline).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        res.send(_.map(results, function (row) {
            row._id.pageViews = row.pageViews;
            row._id.nameVersion = row._id.name + ' ' + row._id.version;
            return row._id;
        }));
    });
};

/* Gets Widget statistics */
exports.getWidgetStats = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    /* Define match step with start and end dates */
    var pipeline = getMatchingPipeline(filters);

    /* Create pipeline */
    pipeline = pipeline.concat({
        $unwind: '$widgets'
    }, {
        $group: {
            _id: '$widgets',
            widgetViews: { $sum: 1 }
        }
    }, {
        $sort: { widgetViews: -1 }
    });

    Analytics.aggregate(pipeline).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        res.send(_.map(results, function(result) {
            return {
                widget: result._id,
                widgetViews: result.widgetViews
            };
        }));
    });
};

/* Gets page views grouped by page number */
exports.getPageViewsByPage = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    /* Define match step with start and end dates */
    var pipeline = getMatchingPipeline(filters);

    /* Create pipeline */
    pipeline = pipeline.concat({
        $group: {
            _id: '$page',
            pageViews: { $sum: 1 }
        }
    }, {
        $sort: { _id: 1 }
    });

    var max = parseInt(req.query.max);
    if (max != 0) {
        pipeline.push({ $limit: max || 100 });
    }

    Analytics.aggregate(pipeline).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        res.send(_.map(results, function (row) {
            return { page: row._id, pageViews: row.pageViews };
        }));
    });
};

/* Gets Data Source statistics by group */
var aggregateDataSources = function (pipeline, res) {

    DataSourceAnalytics.aggregate(pipeline).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        results = _.map(results, function (result) {
            result = _.merge(result, result._id);
            delete result._id;
            return result;
        });

        Analytics.populate(results, { path: 'dashboard', select: 'name' }, function (err, populatedResults) {
            if (err) {
                console.log(err);
                return res.status(500).send(err);
            }

            res.send(_.map(populatedResults, function (row) {
                if (row.dashboard) {
                    row.dashboardName = row.dashboard.name;
                    delete row.dashboard;
                }
                return row;
            }));
        });
    });
};

/* Gets Data Source statistics by Data Source type */
exports.getDataSourcesByType = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard);

    var pipeline = getMatchingPipeline(filters);

    pipeline = pipeline.concat({
        $group: {
            _id: { 
                dataSourceType: '$dataSourceType'
            },
            count: { $sum: 1 },
            avgDuration: { $avg: '$duration' },
            successCount: { $sum: { $cond: [ '$success', 1, 0 ]}}
        }
    }, {
        $project: {
            count: 1,
            avgDuration: 1,
            successCount: 1,
            successRate: { $divide: ['$successCount', '$count'] }
        }
    }, {
        $sort: { count: -1 }
    });

    /* Match all dashboards, limit results */
    var max = parseInt(req.query.max);
    if (_.isUndefined(req.query.dashboard) && max != 0) {
        pipeline.push({ $limit: max || 20 });
    }

    aggregateDataSources(pipeline, res);
};

/* Gets Data Source statistics by Data Source name */
exports.getDataSourcesByName = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard);

    var pipeline = getMatchingPipeline(filters);

    pipeline = pipeline.concat({
        $group: {
            _id: { 
                dataSourceType: '$dataSourceType',
                dashboard: '$dashboard',
                dataSourceName: '$dataSourceName'
            },
            count: { $sum: 1 },
            avgDuration: { $avg: '$duration' },
            successCount: { $sum: { $cond: [ '$success', 1, 0 ]}}
        }
    }, {
        $project: {
            count: 1,
            avgDuration: 1,
            successCount: 1,
            successRate: { $divide: ['$successCount', '$count'] }
        }
    }, {
        $sort: { count: -1 }
    });

    /* Match all dashboards, limit results */
    var max = parseInt(req.query.max);
    if (_.isUndefined(req.query.dashboard) && max != 0) {
        pipeline.push({ $limit: max || 100 });
    }

    aggregateDataSources(pipeline, res);
};

/* Gets failed Data Source statistics by error message */
exports.getDataSourcesByErrorMessage = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard);

    var pipeline = getMatchingPipeline(filters);

    if (pipeline.length == 0) {
        pipeline.push({ $match: {} });
    }

    /* Match by existence of error message */
    pipeline[0].$match['details.errorMessage'] = { $exists: true };

    pipeline = pipeline.concat({
        $group: {
            _id: { 
                errorMessage: '$details.errorMessage'
            },
            count: { $sum: 1 },
            avgDuration: { $avg: '$duration' }
        }
    }, {
        $sort: { count: -1 }
    });

    /* Match all dashboards, limit results */
    var max = parseInt(req.query.max);
    if (_.isUndefined(req.query.dashboard) && max != 0) {
        pipeline.push({ $limit: max || 20 });
    }

    aggregateDataSources(pipeline, res);
};
