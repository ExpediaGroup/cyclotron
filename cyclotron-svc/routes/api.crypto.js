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
 * Crypto API -- encrypt strings with Cyclotron's encryption key
 *
 */

var config = require('../config/config'),
    _ = require('lodash'),
    crypto = require('crypto');

/* Encrypt a string with Cyclotron's encryption key and return the encrypted version */
exports.encrypt = function (req, res) {
    if (_.isEmpty(req.body)) {
        return res.status(400).send('Missing body in request.');
    }
    if (_.isEmpty(req.body.value)) {
        return res.status(400).send('Missing "value" in request body.');
    }
    if (_.isUndefined(config.encryptionKey)) {
        return res.status(500).send('Cyclotron-svc is not configured for encryption.');
    }

    var cipher = crypto.createCipher('aes-256-cbc', config.encryptionKey);
    var encrypted = cipher.update(req.body.value, 'utf8', 'base64');
    encrypted += cipher.final('base64');
    res.send(encrypted);
};

/* Decrypt a string encrypted by Cyclotron.  This should not be exposed */
exports.decrypt = function (req, res) {
    if (_.isEmpty(req.body)) {
        return res.status(400).send('Missing body in request.');
    }
    if (_.isEmpty(req.body.value)) {
        return res.status(400).send('Missing "value" in request body.');
    }
    if (_.isUndefined(config.encryptionKey)) {
        return res.status(500).send('Cyclotron-svc is not configured for encryption.');
    }

    var cipher = crypto.createDecipher('aes-256-cbc', config.encryptionKey);
    var encrypted = cipher.update(req.body.value, 'base64', 'utf8');
    encrypted += cipher.final('utf8');

    res.send(encrypted);
};

exports.ciphers = function (req, res) {
    res.send(crypto.getCiphers());
};
