/* 
 API for Analytics
*/

var config = require('../config/config'),
    _ = require('lodash'),
    later = require('later'),
    moment = require('moment'),
    mongoose = require('mongoose'),
    api = require('./api');
    
var Analytics = mongoose.model('analytics'),
    Dashboards = mongoose.model('dashboard2');

/* Log a Dashboard/Page visit */
exports.recordVisit = function (req, res) {
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

    /* Create new record in the Analytics collection */
    var analytic = new Analytics(record);
    analytic.save();

    /* Increment counters on the Dashboard document */
    var visitInc = 0;
    if (req.query.newVisit == 'true') {
        visitInc = 1;
    }

    Dashboards.findOneAndUpdate({ _id: record.dashboard}, {
        $inc: { 
            pageLoads: 1,
            visits: visitInc,
        }
    }).exec();
};

/* Gets all analytics records (for debugging) */
exports.get = function (req, res) {
    Analytics.find()
        .sort('-date')
        .limit(100)
        .populate('dashboard', 'name')
        .populate('user', 'sAMAccountName')
        .exec(_.wrap(res, api.getCallback));
};

exports.getLastMinute = function (req, res) {
    var endDate = moment().startOf('minute'),
        beginDate = endDate.clone().subtract(1, 'minutes');

    console.log('Begin Date: ' + beginDate.format());
    console.log('End Date: ' + endDate.format());

    Analytics.aggregate([{
        $match: {
            date: { 
                $gte: beginDate.toDate(),
                $lt: endDate.toDate()
            }
        }
    }]).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        res.send(results);
    });
};

/* Gets count of unique visits for a dashboard */
exports.getDashboardVisits = function (req, res) {
    var name = req.params.name.toLowerCase();
    Dashboards
        .findOne({ name: name })
        .exec(function (err, dashboard) {
            if (err) {
                console.log(err);
                return res.status(500).send(err);
            } else if (_.isUndefined(dashboard) || _.isNull(dashboard)) {
                return res.status(404).send('Dashboard not found.');
            }

            Analytics.aggregate([{ 
                $group: {
                    _id: { VisitId: '$visitId' },
                    PlayerCount: { $sum: 1 }
                }
            }]).exec(function (err, visits) {
                if (err) {
                    console.log(err);
                    return res.status(500).send(err);
                }
                res.send(visits)
            });

            /*Analytics.aggregate([
                { $match: { 'dashboard': dashboard._id }},
                { $group: { 
                    visitId: {$first: '$game_name'}, 
                    game_id: {$first: '$game_id'}, 
                    number_plays: {$first:'$number_plays'}
                }}
            ], function (err,list){
                console.log(list);
                res.end();
            });*/
        });
};

/* Gets count of unique visits per dashboard */
exports.getVisitsPerDashboard = function (req, res) {
    Analytics.aggregate([{
        $group: {
            _id: { dashboard: '$dashboard', visitId: '$visitId' },
        }
    }, { 
        $group: {
            _id: '$_id.dashboard',
            dashboard: { $first: '$_id.dashboard' },
            visitCount: { $sum: 1 }
        }
    }, {
        $sort: { visitCount: -1 }
    }]).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        Analytics.populate(results, { path: 'dashboard', select: 'name' }, function (err, populatedResults) {
            if (err) {
                console.log(err);
                return res.status(500).send(err);
            }

            res.send(_.map(populatedResults, function (result) {
                return {
                    _id: result._id,
                    dashboardName: result.dashboard.name,
                    visitCount: result.visitCount
                };
            }));
        });
    });
};

/* Gets count of unique page loads per dashboard */
exports.getPageloadsPerDashboard = function (req, res) {
    Analytics.aggregate([{ 
        $group: {
            _id: '$dashboard',
            dashboard: { $first: '$dashboard' },
            pageLoadCount: { $sum: 1 }
        }
    }]).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }
        Analytics.populate(results, { path: 'dashboard', select: 'name' }, function (err, populatedResults) {
            if (err) {
                console.log(err);
                return res.status(500).send(err);
            }

            res.send(_.map(populatedResults, function (result) {
                return {
                    _id: result._id,
                    dashboardName: result.dashboard.name,
                    pageLoadCount: result.pageLoadCount
                };
            }));
        })
    });
};




/* Aggregated Analytics: timer-based aggregation and storage of aggregated stats per dashboard */
var aggregator = function () {
    console.log('Aggregating! (' + moment().format() + ')');

    var endDate = moment().startOf('minute'),
        beginDate = endDate.clone().subtract(1, 'minutes');

    /* Visitor -> one or more Visits -> one or more Pageloads */
    Analytics.aggregate([{
        $match: {
            date: { 
                $gte: beginDate.toDate(),
                $lt: endDate.toDate()
            }
        }
    }, {
        $group: {
            _id: { dashboard: '$dashboard', user: { $ifNull: ['$user', '$uid'] }, visitId: '$visitId' },
            pageLoadCount: { $sum: 1 }
        }
    }, {
        $group: {
            _id: { dashboard: '$_id.dashboard', user: '$_id.user' },
            pageLoadCount: { $sum: '$pageLoadCount' },
            visitCount: { $sum: 1 }
        }
    }, {
        $group: {
            _id: { dashboard: '$_id.dashboard' },
            pageLoadCount: { $sum: '$pageLoadCount' },
            visitCount: { $sum: '$visitCount' },
            visitorCount: { $sum: 1}
        }
    }]).exec(function (err, results) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        console.log(results);
    });
};

/* Schedule aggregation if enabled */
/*if (config.enableAnalytics == true) {
    // 'every 1 minute starting on the 1st second'
    var schedule = later.parse.recur().on(1).second(),
        t = later.setInterval(aggregator, schedule);
}*/
