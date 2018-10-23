###
# Copyright (c) 2013-2018 the original author or authors.
#
# Licensed under the MIT License (the "License");
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at
#
#     http://www.opensource.org/licenses/mit-license.php
#
# Unless required by applicable law or agreed to in writing, 
# software distributed under the License is distributed on an 
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific 
# language governing permissions and limitations under the License. 
###

# Karma configuration
module.exports = (config) ->
    config.set {

        # base path, that will be used to resolve all patterns, eg. files, exclude
        basePath: '../'

        # frameworks to use
        frameworks: [
            'jasmine'
            'jasmine-matchers'
        ]

        preprocessors:
            'test/**/*.coffee': ['coffee']
            '_public/js/app.*.js': ['coverage']

        # list of files / patterns to load in the browser
        files: [
            '_public/js/vendor.js'
            'bower_components/angular-mocks/angular-mocks.js'
            '_public/js/app.common.js'
            '_public/js/app.dashboards.js'
            '_public/js/conf/sample.configService.js'
            'test/**/*-spec.coffee'
        ]

        # list of files to exclude
        exclude: [
        ]

        # test results reporter to use
        # possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
        reporters: ['nested', 'coverage']

        # web server port
        port: 9876

        # enable / disable colors in the output (reporters and logs)
        colors: true

        # level of logging
        # possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
        logLevel: config.LOG_INFO

        # enable / disable watching file and executing tests whenever any file changes
        autoWatch: false

        # Start these browsers, currently available:
        # - Chrome
        # - ChromeCanary
        # - Firefox
        # - Opera
        # - Safari (only Mac)
        # - PhantomJS
        # - IE (only Windows)
        browsers: [
            #'PhantomJS'
            #'Firefox'
            #'Chrome'
            'ChromeHeadless'
        ]

        # If browser does not capture in given timeout [ms], kill it
        captureTimeout: 60000

        # Continuous Integration mode
        # if true, it capture browsers, run tests and exit
        singleRun: true
    }
