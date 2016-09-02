/*
 * Copyright (c) 2016 the original author or authors.
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

/* Initialize Elasticsearch */
var _ = require('lodash'),
    moment = require('moment'),
    elasticsearch = require('elasticsearch'),
    config = require('./config/config');

if (_.isUndefined(config.analytics.elasticsearch.host)) {
    console.error('Required config missing: "analytics.elasticsearch.host".');
    return;
}

var elasticsearchConfig = config.analytics.elasticsearch;

/* Connect to Elasticsearch */
console.log('Connecting to: ' + JSON.stringify(elasticsearchConfig.host));
var client = new elasticsearch.Client({
  host: elasticsearchConfig.host,
  log: 'info'
});

exports.client = client;

exports.indexAlias = function (type) {
    return elasticsearchConfig.indexPrefix + '-' + type;
}

/**
 * Daily index naming strategy
 */
var getDailyIndexName = function (type, date) {
    var moment2 = moment(date).utc();
    return elasticsearchConfig.indexPrefix + '-' + type + '-daily-' + moment2.format('YYYY-MM-DD');
};

/**
 * Weekly index naming strategy
 */
var getWeeklyIndexName = function (type, date) {
    var moment2 = moment(date).utc().startOf('week');
    return elasticsearchConfig.indexPrefix + '-' + type + '-weekly-' + moment2.format('YYYY-MM-DD');
};

/**
 * Monthly index naming strategy
 */
var getMonthlyIndexName = function (type, date) {
    var moment2 = moment(date).utc();
    return elasticsearchConfig.indexPrefix + '-' + type + '-monthly-' + moment2.format('YYYY-MM') + '-01';
};

/**
 * Yearly index naming strategy
 */
var getYearlyIndexName = function (type, date) {
    var moment2 = moment(date).utc();
    return elasticsearchConfig.indexPrefix + '-' + type + '-yearly-' + moment2.format('YYYY') + '-01-01';
};

/* Determine time-based index naming strategy */
switch(elasticsearchConfig.pageviewsIndexStrategy) {
    case 'daily':
        exports.pageviewsIndexStrategy = _.partial(getDailyIndexName, 'pageviews');
        break;
    case 'weekly':
        exports.pageviewsIndexStrategy = _.partial(getWeeklyIndexName, 'pageviews');
        break;
    case 'monthly':
        exports.pageviewsIndexStrategy = _.partial(getMonthlyIndexName, 'pageviews');
        break;
    case 'yearly': 
        exports.pageviewsIndexStrategy = _.partial(getYearlyIndexName, 'pageviews');
        break;
    default: 
        exports.pageviewsIndexStrategy = _.partial(getWeeklyIndexName, 'pageviews');
}

switch(elasticsearchConfig.datasourcesIndexStrategy) {
    case 'daily':
        exports.datasourcesIndexStrategy = _.partial(getDailyIndexName, 'datasources');
        break;
    case 'weekly':
        exports.datasourcesIndexStrategy = _.partial(getWeeklyIndexName, 'datasources');
        break;
    case 'monthly':
        exports.datasourcesIndexStrategy = _.partial(getMonthlyIndexName, 'datasources');
        break;
    case 'yearly': 
        exports.datasourcesIndexStrategy = _.partial(getYearlyIndexName, 'datasources');
        break;
    default: 
        exports.datasourcesIndexStrategy = _.partial(getWeeklyIndexName, 'datasources');
}

switch(elasticsearchConfig.eventsIndexStrategy) {
    case 'daily':
        exports.eventsIndexStrategy = _.partial(getDailyIndexName, 'events');
        break;
    case 'weekly':
        exports.eventsIndexStrategy = _.partial(getWeeklyIndexName, 'events');
        break;
    case 'monthly':
        exports.eventsIndexStrategy = _.partial(getMonthlyIndexName, 'events');
        break;
    case 'yearly': 
        exports.eventsIndexStrategy = _.partial(getYearlyIndexName, 'events');
        break;
    default: 
        exports.eventsIndexStrategy = _.partial(getWeeklyIndexName, 'events');
}

/* Create/Update Index Templates */
var fs = require('fs');
var files = fs.readdirSync(__dirname + '/config/');
_(files)
    .filter(function (file) { return file.match(/-template\.json$/) !== null; })
    .each(function(file) {
        console.log('Loading Elasticsearch Index Template: ' + file);
        var name = file.replace('.json', '');
        var template = require('./config/' + name);

        /* Update Template name and alias with prefix */
        template.template = elasticsearchConfig.indexPrefix + template.template;
        template.aliases = {};
        template.aliases[template.template.replace('-*', '')] = {};
        
        client.indices.putTemplate({
            name: template.template,
            body: template
        }, function (err, response, status) {
            if (err) { 
                console.log(err);
            }

            console.log('Elasticsearch Index Template: ' + file + ' ' + JSON.stringify(response));
        });
    });

