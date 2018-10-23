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
 * Proxy API -- generic HTTP reverse proxy
 *
 * Expects a payload matching request's options:
 *   https://www.npmjs.com/package/request
 */

var config = require('../config/config'),
    _ = require('lodash'),
    request = require('request'),
    aws4 = require('aws4'),
    crypto = require('crypto');

/* Crypto-process request options */
var decrypter = function (req) {
    var decrypt = function (value) {
        if (_.isString(value)) {
            /* Decrypt */
            return value.replace(/!(\{|%7B)(.*?)(\}|%7D)/gi, function (all, opener, inner, closer) {
                var uriDecoded = decodeURIComponent(inner);
                var cipher = crypto.createDecipher('aes-256-cbc', config.encryptionKey);
                var encrypted = cipher.update(uriDecoded, 'base64', 'utf8');
                encrypted += cipher.final('utf8');
                return encrypted;
            });
        } else if (_.isArray(value)) {
            return _.map(value, decrypt);
        } else if (_.isObject(value)) {
            return _.mapValues(value, decrypt);
        } else {
            return value;
        }
    };
    return _.mapValues(req, decrypt);
}

var sendRequest = function (req, callback) {
    var proxyRequest = decrypter(req);

    if (proxyRequest.awsCredentials) {
        /* Should contain { accessKeyId: '', secretAccessKey: '' } */
        aws4.sign(proxyRequest, proxyRequest.awsCredentials);
    }

    request(proxyRequest, function (err, proxyResponse, body) {
        if (err) {
            console.log('Proxy Error: ' + err + ' ' + JSON.stringify(proxyResponse) + ', err.connect: ' + err.connect);
            return callback({
                error: err,
                proxyResponse: proxyResponse,
                body: body
            });
        }

        if (_.isString(body) 
            && req.json != false
            && proxyResponse != null 
            && proxyResponse.headers != null
            && proxyResponse.headers['content-type']
            && proxyResponse.headers['content-type'].toLowerCase().indexOf('application/json') >= 0) {
            body = JSON.parse(body);
        }

        console.log('Proxy complete');
        callback({
            proxyResponse: proxyResponse,
            statusCode: proxyResponse.statusCode,
            headers: proxyResponse.headers,
            body: body
        });
    });
};

/* Generic HTTP Proxy */
exports.proxy = function (req, res) {
    /* Increase connection timeout: 5 minutes */
    req.connection.setTimeout(300*1000);

    if (req.body == null) {
        return res.status(400).send('Missing body in request.');
    }

    if (_.isUndefined(config.encryptionKey)) {
        return res.status(500).send('Cyclotron-svc is not configured for encryption.');
    }

    sendRequest(req.body, function (response) {
        if (response.error) {
            return res.status(500).send('Error in proxy request: ' + response.error + ' ' + JSON.stringify(response.proxyResponse));
        } else {
            res.send({ 
                statusCode: response.statusCode,
                headers: response.headers,
                body: response.body
            });
        }
    });
};

