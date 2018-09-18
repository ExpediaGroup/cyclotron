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
 * API for LDAP operations
 * 
 * LDAP search functionality drives auto-completion of users & groups for Dashboard permissions.
 */

var config = require('../config/config'),
    _ = require('lodash'),
    Promise = require('bluebird'),
    ldap = require('ldapjs');
    api = require('./api');

/* Exclude special characters; can't begin or end with a wildcard, as those are built-in */
var validQueryRegex = /^[^=*\(\)]([^=\(\)]*[^=*\(\)]+)?$/i;

/* Search Everything (Security Groups, DLs, etc) */
exports.search = function (req, res) {
    
    var nameFilter = req.query.q || ''
    if (!validQueryRegex.test(nameFilter)) {
        console.log('Search query failed validation');
        return res.status(500).send('Invalid Query');
    }
    var ldapFilter = '(|(sAMAccountName=*' + nameFilter + '*)(displayName=*' + nameFilter + '*))';

    var searchCategories = config.ldap.searchCategories;
    if (_.isEmpty(searchCategories)) {
        return res.status(500).send('No search categories configured for service.');
    }

    /* Run the filter thorugh each search category and collect the results */
    var promises = _.map(searchCategories, function(category) {
        return ldapSearch(category.name, category.dn, ldapFilter, category.scope);
    });

    Promise.all(promises).then(function (result) {
        return res.send(_.sortBy(_.flatten(result), 'name'));
    }).catch(function (err) {
        return res.status(500).send(err);
    });
};

/* Perform LDAP search and resolve a promise */
var ldapSearch = function(categoryName, dn, filter, scope) {
    if (_.isUndefined(scope) || _.isNull(scope)) {
        scope = 'sub';
    }

    var searchOptions = {
        filter: filter,
        attributes: [
            'distinguishedName', 
            'name', 
            'displayName', 
            'sAMAccountName', 
            'objectCategory', 
            'description', 
            'memberOf', 
            'department', 
            'division',
            'mail',
            'title'
        ],
        scope: scope
    };

    var client = ldap.createClient({
        url: config.ldap.url,
        bindDn: config.ldap.adminDn,
        bindCredentials: config.ldap.adminPassword
    });

    return new Promise(function (resolve, reject) {

        client.bind(config.ldap.adminDn, config.ldap.adminPassword, function (err) {

            client.search(dn, searchOptions, function (err, result) {
                if (err) {
                    client.unbind();
                    return reject(err);
                }

                var items = [];
                
                result.on('searchEntry', function (entry) {
                    items.push(entry.object);
                });

                result.on('error', function (err) {
                    client.unbind();
                    return reject(err);
                });

                result.on('end', function (result) {
                    _.each(items, function (item) {
                        item.category = categoryName;
                        if (_.isString(item.memberOf)) {
                            item.memberOf = [item.memberOf];
                        }

                        if (!_.has(item, 'displayName')) {
                            item.displayName = item.name;
                        }

                        delete item.controls;
                    });

                    resolve(items);

                    client.unbind();
                });
            });
        })

    });
}
