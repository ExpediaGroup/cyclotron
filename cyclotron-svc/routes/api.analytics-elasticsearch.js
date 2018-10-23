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
 * API for Analytics - Elasticsearch implementation
 */

var config = require('../config/config'),
    _ = require('lodash'),
    moment = require('moment'),
    mongoose = require('mongoose'),
    Promise = require('bluebird'),
    api = require('./api'),
    auth = require('./auth');

var Dashboards = mongoose.model('dashboard2');
    
var elasticsearch = require('../elastic');

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
    record.browser.nameVersion = record.browser.name + ' ' + record.browser.version;
    if (!_.isEmpty(record.widgets)) {
        record.widgets = _.map(record.widgets, function (widget) {
            return { name: widget };
        });
    }

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
        /* Index a new document in Elasticsearch */
        elasticsearch.client.index({
            index: elasticsearch.pageviewsIndexStrategy(record.date),
            type: 'pageview',
            body: record
        }, function (err, result) {
            if (err) {
                console.log('Elasticsearch Error: ' + JSON.stringify(err));
            }
        });

        pageViewInc = 1;

        /* Increment counters on the Dashboard document */
        if (req.query.newVisit == 'true') {
            visitInc = 1;
        }
    }

    /* Increment counters on Dashboard */
    Dashboards.findOneAndUpdate({ _id: record.dashboard._id}, {
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

    /* Index a new document in Elasticsearch */
    elasticsearch.client.index({
        index: elasticsearch.datasourcesIndexStrategy(record.date),
        type: 'datasource',
        body: record
    }, function (err, result) {
        if (err) {
            console.log('Elasticsearch Error: ' + JSON.stringify(err));
        }
    });
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

    /* Index a new document in Elasticsearch */
    elasticsearch.client.index({
        index: elasticsearch.eventsIndexStrategy(record.date),
        type: 'event',
        body: record
    }, function (err, result) {
        if (err) {
            console.log('Elasticsearch Error: ' + JSON.stringify(err));
        }
    });
};

var deleteDocumentsForQuery = function (index, query) {
    return new Promise(function (resolve, reject) {
        var totalHitCount = 0;
        var collectMoreResults = function (err, response) {
            if (err) {
                return reject(err);
            }

            var documents = [];

            _.each(response.hits.hits, function (hit) {
                documents.push(_.pick(hit, ['_id', '_index', '_type']));
                totalHitCount++;
            });

            var bulkDeletes = _.map(documents, function (document) {
                return { delete: document };
            })

            if (!_.isEmpty(bulkDeletes)) {
                console.log('Bulk Deleting: ' + bulkDeletes.length + ' ' + index);
                /* Submit bulk delete request */
                elasticsearch.client.bulk({
                    body: bulkDeletes
                }).catch(err, function (err) {
                    reject(err);
                });
            }

            /* Continue with scrolling */
            if (response.hits.total !== totalHitCount) {
                elasticsearch.client.scroll({
                    scrollId: response._scroll_id,
                    scroll: '30s'
                }, collectMoreResults);
            } else {
                resolve();
            }
        };

        elasticsearch.client.search({
            index: index,
            scroll: '30s',
            search_type: 'scan',
            q: query
        }, collectMoreResults);
    });
};

exports.deleteAnalyticsForDashboard = function (req, res) {

    if (!auth.isAdmin(req)) {
        return res.status(403).send('Permission denied.');
    }

    var dashboardId = req.query.dashboard;

    if (_.isUndefined(dashboardId)) {
        return res.status(400).send('Missing Dashboard ID.');
    }

    /* Delete Page Views */
    var pageViewsPromise = deleteDocumentsForQuery(
        elasticsearch.indexAlias('pageviews'),
        'dashboard._id:' + dashboardId);
    /* Delete Data Sources */
    var dataSourcesPromise = deleteDocumentsForQuery(
        elasticsearch.indexAlias('datasources'),
        'dashboard._id:' + dashboardId);

    Promise.all([pageViewsPromise, dataSourcesPromise]).then(function () {
        
        /* Update Dashboard in MongoDB */
        Dashboards.findOneAndUpdate({ _id: new mongoose.Types.ObjectId(dashboardId) }, 
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
        });
    }).catch(function (err) {
        console.log('Error deleting analytics for dashboard.');
        console.log(err);
        return res.status(500).send(err);
    });
};

/* Gets 100 most-recent Page View analytics records */
exports.getRecentPageViews = function (req, res) {
    var query = null;

    if (_.isUndefined(req.query.dashboard)) {
        query = { match_all: {} };
    } else {
        query = { "term": { "dashboard._id": req.query.dashboard }};
    }

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('pageviews'),
        body: {
            size: req.query.max || 100, 
            query: query, 
            sort: [{ date: { order: 'desc' }}] 
        }
    }).then(function (response) {
        res.send(_.map(response.hits.hits, '_source'));
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets 100 most-recent Data Source analytics records */
exports.getRecentDataSources = function (req, res) {
    var query = null;

    if (_.isUndefined(req.query.dashboard)) {
        query = { match_all: {} };
    } else {
        query = { "term": { "dashboard._id": req.query.dashboard }};
    }

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('datasources'),
        body: {
            size: req.query.max || 100, 
            query: query, 
            sort: [{ date: { order: 'desc' }}] 
        }
    }).then(function (response) {
        res.send(_.map(response.hits.hits, '_source'));
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets 100 most-recent Event analytics records */
exports.getRecentEvents = function (req, res) {
    var query = null;

    if (_.isUndefined(req.query.type)) {
        query = { match_all: {} };
    } else {
        query = { "term": { "eventType": req.query.type }};
    }

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('events'),
        body: {
            size: req.query.max || 100, 
            query: query, 
            sort: [{ date: { order: 'desc' }}] 
        }
    }).then(function (response) {
        res.send(_.map(response.hits.hits, '_source'));
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets 100 most-visited Dashboards */
exports.getTopDashboards = function (req, res) {
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);
    var max = parseInt(req.query.max);

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('pageviews'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                dashboards: {
                    terms: {
                        field: 'dashboard._id',
                        order: { _count : 'desc' },
                        size: max || 100
                    }
                }
            } 
        }
    }).then(function (response) {
        Dashboards.populate(response.aggregations.dashboards.buckets, { 
            path: 'key', 
            select: '-dashboard -editors -viewers'
        }, function (err, populatedResults) {
            if (err) {
                console.log(err);
                return reject(err);
            }

            res.send(_.compact(_.map(populatedResults, function(result) {
                return result.key;
            })));
        });
    }).catch(function (err) {
        res.status(500).send(err);
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

/* Create a query object using filters */
var getQuery = function (filters) {
    var must = [];

    /* Start Date / End Date filter */
    if (!_.isUndefined(filters.startDate) && !_.isUndefined(filters.endDate)) {
        must.push({
            range: {
                date: {
                    gte: filters.startDate,
                    lte: filters.endDate
                }
            }
        });
    } else if (!_.isUndefined(filters.startDate)) {
        must.push({
            range: {
                date: {
                    gte: filters.startDate
                }
            }
        });
    } else if (!_.isUndefined(filters.endDate)) {
        must.push({
            range: {
                date: {
                    lte: filters.endDate
                }
            }
        });
    }

    /* Dashboard filter */
    if (!_.isUndefined(filters.dashboardId)) {
        must.push({
            term: {
                'dashboard._id': filters.dashboardId
            }
        });
    }

    if (must.length == 0) {
        return { match_all: {} };
    }
    return { query: { bool: { must: must } } };
}

/* Gets all page views over time, grouped by (minute|hour|day) */
exports.getPageViewsOverTime = function (req, res) {

    if (!_.isUndefined(req.query.resolution)) {
        if (req.query.resolution != 'day' && req.query.resolution != 'hour' && req.query.resolution != 'minute') {
            return res.status(400).send('Invalid resolution (day, hour, minute).');
        }
    }

    var filters = getFiltersWithDefaultDates(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('pageviews'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                time: {
                    date_histogram: {
                        field: 'date',
                        interval: filters.resolution,
                        min_doc_count: 0,
                        extended_bounds: {
                            min: filters.startDate.toISOString(),
                            max: filters.endDate.toISOString()
                        }
                    }
                }
            } 
        }
    }).then(function (response) {
        var results = _.map(response.aggregations.time.buckets, function (bucket) {
            return {
                date: bucket.key_as_string,
                pageViews: bucket.doc_count
            };
        });
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets all visits over time, grouped by (minute|hour|day) */
exports.getVisitsOverTime = function (req, res) {
    
    if (!_.isUndefined(req.query.resolution)) {
        if (req.query.resolution != 'day' && req.query.resolution != 'hour' && req.query.resolution != 'minute') {
            return res.status(400).send('Invalid resolution (day, hour, minute).');
        }
    }

    var filters = getFiltersWithDefaultDates(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('pageviews'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                time: {
                    date_histogram: {
                        field: 'date',
                        interval: filters.resolution,
                        min_doc_count: 0,
                        extended_bounds: {
                            min: filters.startDate.toISOString(),
                            max: filters.endDate.toISOString()
                        }
                    },
                    aggs: {
                        distinctVisits: {
                            cardinality: {
                                field: 'visitId',
                                precision_threshold: 100
                            }
                        }
                    }
                }
            } 
        }
    }).then(function (response) {
        var results = _.map(response.aggregations.time.buckets, function (bucket) {
            return {
                date: bucket.key_as_string,
                visits: bucket.distinctVisits.value
            };
        });
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets unique visitors */
exports.getUniqueVisitors = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);
    var max = parseInt(req.query.max);

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('pageviews'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                anonymous: {
                    filter: { not: { exists: { field: 'user' } } },
                    aggs: {
                        users: {
                            terms: {
                                field: 'uid',
                                size: max || 100,
                                order: {
                                    _count: 'desc'
                                }
                            },
                            aggs: {
                                topIp: {
                                    top_hits: {
                                        size: 1,
                                        _source: {
                                            include: ['ip']
                                        },
                                        sort: [{
                                            'ip': {
                                                order: 'asc'
                                            }
                                        }]
                                    }
                                }
                            }
                        }
                    }
                },
                authenticated: {
                    filter: { exists: { field: 'user' } },
                    aggs: {
                        users: {
                            terms: {
                                field: 'user._id',
                                size: max || 100,
                                order: {
                                    _count: 'desc'
                                }
                            },
                            aggs: {
                                topUser: {
                                    top_hits: {
                                        size: 1,
                                        _source: {
                                            include: [
                                                'user._id',
                                                'user.sAMAccountName',
                                                'user.name'
                                            ]
                                        },
                                        sort: [{
                                            'user.name': {
                                                order: 'asc'
                                            }
                                        }]
                                    }
                                }
                            }
                        }
                    }
                }
            } 
        }
    }).then(function (response) {
        var authenticatedUsers = _.map(response.aggregations.authenticated.users.buckets, function (user) {
            return {
                user: user.topUser.hits.hits[0]._source.user,
                pageViews: user.doc_count
            };
        });

        var anonymousUsers = _.map(response.aggregations.anonymous.users.buckets, function (user) {
            return {
                uid: user.key,
                ip: user.topIp.hits.hits[0]._source.ip,
                pageViews: user.doc_count
            };
        });

        /* Combine authenticated and anonymous users and sort */
        var results = _.orderBy(_.union(anonymousUsers, authenticatedUsers), ['pageViews'], ['desc']);

        /* Limit results */
        if (!_.isNull(max) && max > 0) {
            results = _.take(results, max);
        }
        
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });  
};

/* Gets browser statistics */
exports.getBrowserStats = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);
    var max = parseInt(req.query.max);

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('pageviews'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                browsers: {
                    terms: {
                        field: 'browser.name',
                        size: max || 10000,
                        order: {
                            _count: 'desc'
                        }
                    },
                    aggs: {
                        versions: {
                            terms: {
                                field: 'browser.version',
                                size: max || 10000,
                                order: {
                                    _count: 'desc'
                                }
                            }
                        }
                    }
                }
            },
            sort: [{ date: { order: 'desc' }}] 
        }
    }).then(function (response) {
        var results = [];
        _.each(response.aggregations.browsers.buckets, function (browser) {
            _.each(browser.versions.buckets, function (version) {
                results.push({
                    name: browser.key,
                    version: version.key,
                    pageViews: version.doc_count,
                    nameVersion: browser.key + ' ' + version.key
                });
            });
        });
        results = _.orderBy(results, ['pageViews'], ['desc']);
        if (max != 0 && !_.isNaN(max)) {
            results = _.take(results, max);
        }
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets Widget statistics */
exports.getWidgetStats = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);

    elasticsearch.client.search({
        index: elasticsearch.indexAlias('pageviews'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                nested: {
                    nested: {
                        path: 'widgets'
                    },
                    aggs: {
                        widgets: {
                            terms: {
                                field: 'widgets.name',
                                size: 100,
                                order: {
                                    _count: 'desc'
                                }
                            }
                        }
                    }
                }
            } 
        }
    }).then(function (response) {
        var results = _.map(response.aggregations.nested.widgets.buckets, function (widget) {
            return {
                widget: widget.key,
                widgetViews: widget.doc_count
            };
        });
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets page views grouped by page number */
exports.getPageViewsByPage = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);
    var max = parseInt(req.query.max);
    elasticsearch.client.search({
        index: elasticsearch.indexAlias('pageviews'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                pages: {
                    terms: {
                        field: 'page',
                        size: max || 100,
                        order: {
                            _count: 'desc'
                        }
                    }
                }
            } 
        }
    }).then(function (response) {
        var results = _.map(response.aggregations.pages.buckets, function (page) {
            return {
                page: page.key,
                pageViews: page.doc_count
            };
        });
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets Data Source statistics by Data Source type */
exports.getDataSourcesByType = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);
    var max = parseInt(req.query.max);
    elasticsearch.client.search({
        index: elasticsearch.indexAlias('datasources'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                dataSourceTypes: {
                    terms: {
                        field: "dataSourceType",
                        size: max || 20,
                        order: {
                            _count: "desc"
                        }
                    },
                    aggs: {
                        avgDuration: { avg: { field: "duration" } },
                        success: {
                            filter: { term: { success: true } }
                        }
                    }
                }
            } 
        }
    }).then(function (response) {
        var results = _.map(response.aggregations.dataSourceTypes.buckets, function (dataSourceType) {
            return {
                dataSourceType: dataSourceType.key,
                count: dataSourceType.doc_count,
                avgDuration: dataSourceType.avgDuration.value,
                successCount: dataSourceType.success.doc_count,
                successRate: dataSourceType.success.doc_count / dataSourceType.doc_count
            };
        });
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets Data Source statistics by Data Source name */
exports.getDataSourcesByName = function (req, res) {
    
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);
    var max = parseInt(req.query.max);
    elasticsearch.client.search({
        index: elasticsearch.indexAlias('datasources'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                dataSourceTypes: {
                    terms: {
                        field: "dataSourceType",
                        size: max || 100,
                        order: {
                            _count: "desc"
                        }
                    },
                    aggs: {
                        dashboards: { 
                            terms: {
                                field: "dashboard.name",
                                size: max || 100,
                                order: {
                                    _count: "desc"
                                }
                            },
                            aggs: {
                                dataSourceNames: { 
                                    terms: {
                                        field: "dataSourceName",
                                        size: max || 100,
                                        order: {
                                            _count: "desc"
                                        }
                                    },
                                    aggs: {
                                        avgDuration: { avg: { field: "duration" } },
                                        success: {
                                            filter: { term: { success: true } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } 
        }
    }).then(function (response) {
        var results = [];

        _.each(response.aggregations.dataSourceTypes.buckets, function (dataSourceType) {
            _.each(dataSourceType.dashboards.buckets, function (dashboard) {
                _.each(dashboard.dataSourceNames.buckets, function (dataSource) {
                    results.push({
                        dataSourceType: dataSourceType.key,
                        dashboardName: dashboard.key,
                        dataSourceName: dataSource.key,
                        count: dataSource.doc_count,
                        avgDuration: dataSource.avgDuration.value,
                        successCount: dataSource.success.doc_count,
                        successRate: dataSource.success.doc_count / dataSource.doc_count
                    });
                });
            });
        });
        results = _.orderBy(results, ['count'], ['desc']);
        if (max != 0 && !_.isNaN(max)) {
            results = _.take(results, max);
        }
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });
};

/* Gets failed Data Source statistics by error message */
exports.getDataSourcesByErrorMessage = function (req, res) {
        
    var filters = getFilters(req.query.startDate, req.query.endDate, req.query.dashboard, req.query.resolution);
    var max = parseInt(req.query.max);
    elasticsearch.client.search({
        index: elasticsearch.indexAlias('datasources'),
        body: {
            size: 0,
            query: getQuery(filters), 
            aggs: {
                failures: {
                    filter: { exists: { field: "details.errorMessage" } },
                    aggs: {
                        errorMessages: {
                            terms: {
                                field: "details.errorMessage.raw",
                                size: max || 20,
                                order: {
                                    _count: "desc"
                                }
                            },
                            aggs: {
                                avgDuration: { avg: { field: "duration" } }
                            }
                        }
                    } 
                }
            } 
        }
    }).then(function (response) {
        var results = _.map(response.aggregations.failures.errorMessages.buckets, function (errorMessage) {
            return {
                errorMessage: errorMessage.key,
                count: errorMessage.doc_count,
                avgDuration: errorMessage.avgDuration.value
            };
        });
        res.send(results);
    }).catch(function (err) {
        res.status(500).send(err);
    });
};
