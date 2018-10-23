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
 * API for Users and Session Management
 */

var config = require('../config/config'),
    _ = require('lodash'),
    api = require('./api'),
    passport = require('passport'),
    auth = require('./auth'),
    mongoose = require('mongoose');

var crypto = require('crypto'); 
    
var Users = mongoose.model('user');

var createSession = function (user, ip) {
    /* Ensure memberOf list is an array */
    var userMemberOf = user.memberOf || []
    if (_.isString(userMemberOf)) {
        userMemberOf = [userMemberOf];
    }

    var email = null;
    var emailHash = null;

    if (!_.isUndefined(user.mail)) {
        email = user.mail.trim().toLowerCase();
        emailHash = crypto.createHash('md5').update(email).digest('hex')
    }

    /* Logged In, Store User in /users */
    return Users.findOneAndUpdateAsync({ sAMAccountName: user.sAMAccountName }, { 
        $set: {
            name: user.displayName,
            sAMAccountName: user.sAMAccountName,
            email: email,
            emailHash: emailHash,
            distinguishedName: user.distinguishedName,
            givenName: user.givenName || user.displayName,
            title: user.title || null,
            department: user.department || null,
            division: user.division || null,
            lastLogin: new Date(),
            memberOf: userMemberOf
        }, 
        $inc: { 
            timesLoggedIn: 1 
        },
        $setOnInsert: {
            firstLogin: new Date()
        }
    }, { 
        new: true,
        upsert: true
    })
    .then(_.partial(auth.createNewSession, ip))
    .spread(function (session) {
        return session.populateAsync('user');
    });
}

/* Gets all Users */
exports.get = function (req, res) {
    Users.find().exec(_.wrap(res, api.getCallback));
};

/* Gets a single User */
exports.getSingle = function (req, res) {
    var name = req.params.name.toLowerCase();
    Users.findOne({ sAMAccountName: name }).exec(_.wrap(res, api.getCallback));
};

/* Login as a User */
exports.login = function (req, res) {

    /* Handle DOMAIN/username and DOMAIN\username by stripping off the DOMAIN */
    if (req.body.username != null) {
        var split = req.body.username.split(/\\|\//);
        if (split.length > 1) {
            req.body.username = split[1];
        }
    }

    passport.authenticate('ldapauth', function (err, user, info) {

        if (err) {
            console.log(err);
            return res.status(500).send('Authentication error: ' + err);
        }
        if (!user) {
            return res.status(401).send('Authentication failure: invalid user or password.');
        }

        createSession(user, req.ip).then(function (session) {
            session.user.admin = _.includes(config.admins, session.user.distinguishedName);

            /* Finally, passport.js login */
            req.login(user, { session: false }, function (err) {
                if (err) {
                    console.log(err);
                    res.status(500).send(err);
                } else {
                    res.send(session);
                }
            });

            /* Cleanup expired sessions */
            auth.removeExpiredSessions();
        })
        .catch(function (err) {
            console.log(err);
            res.status(500).send(err);
        });
    })(req, res);
};

/* Test a Session key for validity, returning the Session if valid. */
exports.validate = function (req, res) {
    var key = req.body.key;

    if (_.isNull(key)) {
        return res.status(400).send('No session key provided.');
    }

    auth.validateSession(key).then(function (session) {
        res.send(session);
    }).catch(function (err) {
        res.status(403).send(err);
    });
};

/* Logout of an active Session */
exports.logout = function (req, res) {
    var key = req.body.key;

    if (_.isNull(key)) {
        return res.status(400).send('No session key provided.');
    }

    auth.removeSession(key).then(function (session) {
        if (_.isNull(session)) {
            res.status(401).send('Session not found.');
        } else {
            req.logout();
            res.send('OK');
        }
    }).catch(function (err) {
        res.status(500).send(err);
    });
};
