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
 * API for Tags
 */

var _ = require('lodash'),
    mongoose = require('mongoose'),
    api = require('./api');

var Dashboards = mongoose.model('dashboard2');

/* Get all tags */
exports.get = function (req, res) {
    Dashboards.find({ deleted: false })
        .select('tags')
        .exec(function (err, dashboards) {
            if (err) {
                console.log(err);
                res.status(500).send(err);
            } else {
                var tags = _(dashboards)
                    .map('tags')
                    .flatten()
                    .compact()
                    .sortBy()
                    .uniq(true)
                    .value();
                res.send(tags);
            }
        });
};

/* Get all tags and name parts for autocomplete */
exports.getSearchHints = function (req, res) {
    Dashboards.find({ deleted: false })
        .select('name tags')
        .exec(function (err, dashboards) {
            if (err) {
                console.log(err);
                res.status(500).send(err);
            } else {
                var tags = _(dashboards)
                    .map('tags')
                    .flatten()
                    .compact()
                    .sortBy()
                    .value();

                var names = _(dashboards)
                    .map('name')
                    .sortBy()
                    .value();

                res.send(_.uniq(_.union(tags, names), true));
            }
        });
};
