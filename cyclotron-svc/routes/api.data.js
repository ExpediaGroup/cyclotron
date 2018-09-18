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
 
var config = require('../config/config'),
    _ = require('lodash'),
    moment = require('moment'),
    mongoose = require('mongoose'),
    api = require('./api');
    
var DataBuckets = mongoose.model('databucket');

exports.get = function (req, res) {
    DataBuckets
        .find()
        .select('-data')
        .exec(_.wrap(res, api.getCallback));
};

exports.getSingle = function (req, res) {
    DataBuckets
        .findOne({ key: req.params.key })
        .exec(_.wrap(res, api.getCallback));
};

exports.deleteSingle = function (req, res) {
    DataBuckets
        .findOne({ key: req.params.key })
        .remove()
        .exec(function (err) {
          if (err) {
              console.log(err);
              return res.status(500).send(err);
          }else{
              return res.send("Data Bucket deleted.");
          }
        });
};

exports.getSingleData = function (req, res) {
    DataBuckets
        .findOne({ key: req.params.key })
        .select('data')
        .exec(function (err, bucket) {
            if (err) {
                console.log(err);
                return res.status(500).send(err);
            } else if (_.isUndefined(bucket) || _.isNull(bucket)) {
                return res.status(404).send('Data Bucket not found.');
            }

            res.send(bucket.data);
        });
};

exports.putPostSingle = function (req, res) {

    if (req.body == null || req.body.key == null) {
        return res.status(400).send('Missing key.');
    }
    if (req.body.data == null) {
        return res.status(400).send('Missing data.');
    }
    
    var databucket = req.body;
    var key = req.params.key || databucket.key;
    
    /* Check if DataBucket exists */
    DataBuckets.findOneAndUpdate({ key: key }, {
        $set: {
            key: key,
            lastModifiedDate: new Date(),
            data: databucket.data
        },
        $setOnInsert: {
            createdDate: new Date()
        },
        $inc: { rev: 1 }
    }, {
        new: true,
        upsert: true
    }).exec(_.wrap(res, api.getCallback));
};

/* Replaces the data bucket with an entirely new array */
exports.putData = function (req, res) {

    if (req.body == null || !_.isArray(req.body)) {
        return res.status(400).send('Missing data.');
    }

    var rev = req.query.rev ? parseInt(req.query.rev) : null;

    DataBuckets.findOne({ key: req.params.key }, function (err, bucket) {
        if (err) {
            res.status(500).send(err);
        } else if (_.isUndefined(bucket) || _.isNull(bucket)) {
            res.status(404).send('Not found.');
        } else {
            /* Optional check for matching revision */
            if (!_.isNull(rev) && rev != bucket.rev) {
                res.status(409).send('Revision number not matching (found ' + bucket.rev + ', expecting ' + rev + ')');
            } else {
                DataBuckets.findOneAndUpdate({ _id: bucket._id }, {
                    $set: {
                        data: req.body
                    },
                    $inc: { rev: 1 }
                }).exec(_.wrap(res, api.getCallback));
            }
        }
    });
};

/* Appends either a single value or array to the data bucket */
exports.appendData = function (req, res) {

    var data = req.body;

    if (data == null) {
        return res.status(400).send('Missing data.');
    }

    /* Wrap in array */
    if (!_.isArray(data)) {
        data = [data];
    }
    
    DataBuckets.findOneAndUpdate({ key: req.params.key }, {
        $pushAll: {
            data: data
        },
        $inc: { rev: 1 }
    }).exec(_.wrap(res, api.getCallback));
};

/* Upserts a single object: creates if it doesn't exist, else updates */
exports.upsertData = function (req, res) {
    if (req.body == null) {
        return res.status(400).send('Missing data.');
    }

    var upsertData = req.body.data;
    var keys = req.body.keys;

    if (upsertData == null) {
        return res.status(400).send('Missing data.');
    }
    if (keys == null) {
        return res.status(400).send('Missing keys.');
    }

    var rev = req.query.rev ? parseInt(req.query.rev) : null;

    DataBuckets.findOne({ key: req.params.key }, function (err, bucket) {
        if (err) {
            res.status(500).send(err);
        } else if (_.isUndefined(bucket) || _.isNull(bucket)) {
            res.status(404).send('Not found.');
        } else {
            /* Optional check for matching revision */
            if (!_.isNull(rev) && rev != bucket.rev) {
                res.status(409).send('Revision number not matching (found ' + bucket.rev + ', expecting ' + rev + ')');
            } else {

                /* Update bucket data: insert new row or merge with existing row */
                matchingRow = _.find(bucket.data, keys);
                if (_.isUndefined(matchingRow)) {
                    bucket.data.push(_.merge(upsertData, keys));
                } else {
                    _.merge(matchingRow, upsertData);
                }

                DataBuckets.findOneAndUpdate({ _id: bucket._id }, {
                    $set: {
                        data: bucket.data
                    },
                    $inc: { rev: 1 }
                }).exec(_.wrap(res, api.getCallback));
            }
        }
    });
};

/* Removes objects from data by matching keys */
exports.removeData = function (req, res) {
    if (req.body == null) {
        return res.status(400).send('Missing data.');
    }

    var keys = req.body;
    var rev = req.query.rev ? parseInt(req.query.rev) : null;

    DataBuckets.findOne({ key: req.params.key }, function (err, bucket) {
        if (err) {
            res.status(500).send(err);
        } else if (_.isUndefined(bucket) || _.isNull(bucket)) {
            res.status(404).send('Not found.');
        } else {
            /* Optional check for matching revision */
            if (!_.isNull(rev) && rev != bucket.rev) {
                res.status(409).send('Revision number not matching (found ' + bucket.rev + ', expecting ' + rev + ')');
            } else {

                /* Remove matching bucket data */
                _.remove(bucket.data, keys);

                DataBuckets.findOneAndUpdate({ _id: bucket._id }, {
                    $set: {
                        data: bucket.data
                    },
                    $inc: { rev: 1 }
                }).exec(_.wrap(res, api.getCallback));
            }
        }
    });
};
