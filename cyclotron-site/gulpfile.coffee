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

gulp = require 'gulp'
concat = require 'gulp-concat'
filter = require 'gulp-filter'
flatten = require 'gulp-flatten'
order = require 'gulp-order2'
output = require 'gulp-output'
plumber = require 'gulp-plumber'
rename = require 'gulp-rename'
merge = require 'merge-stream'

fs = require 'fs'
del = require 'del'
path = require 'path'

bower = require 'gulp-bower'
mainBowerFiles = require 'main-bower-files'

pug = require 'gulp-pug'

coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
ngAnnotate = require 'gulp-ng-annotate'
uglify = require 'gulp-uglify'

less = require 'gulp-less'
cleanCss = require 'gulp-clean-css'
concatCss = require 'gulp-concat-css'
urlAdjuster = require 'gulp-css-url-adjuster'

connect = require 'gulp-connect'
karma = require 'karma'

_ = require 'lodash'

coffeeOptions =
    bare: true
    # Use our version instead of bundled
    coffee: require('coffeescript') 

coffeelintOptions =
    indentation:
        value: 4
    no_trailing_semicolons:
        level: 'ignore'
    no_trailing_whitespace:
        level: 'ignore'
    max_line_length:
        value: 120
        level: 'ignore'

ngAnnotateOptions =
    add: true
    remove: true
    single_quotes: true

plumberError = (error) ->
    console.log(error)
    this.emit('end')

gulp.task 'clean', -> del(['./_public', './coverage', 'bower_components'])

gulp.task 'bower-install', -> 
    bower()
        .pipe(gulp.dest('bower_components'))

gulp.task 'vendor-styles', ->
    cssFilter = filter '**/*.css'
    lessFilter = filter '**/*.less', { restore: true }

    bowerCss = gulp.src mainBowerFiles()
        .pipe cssFilter

    vendorCss = gulp.src [
        './vendor/**/*.css'
        './vendor/**/*.less'
        '!./vendor/**/_*.less'
    ]

    merge(bowerCss, vendorCss)
        .pipe plumber()
        #.pipe output { destination: 'css.text'}
        .pipe lessFilter
        .pipe less()
        .pipe lessFilter.restore

        .pipe flatten()
        .pipe urlAdjuster { replace:  ['select2','/img/select2'] }
        .pipe urlAdjuster { replace:  [/^\.\/fonts\/.*?\//,'../fonts/'] }
        .pipe urlAdjuster { replace:  [/\.\.\/font\/.*?\//,'../fonts/'] }
        .pipe concat 'vendor.css'
        .pipe gulp.dest './_public/css'

gulp.task 'vendor-scripts', ->
    jsFilter = filter '**/*.js'
    webWorkerFilter = filter 'worker-*.js'

    bowerScripts = gulp.src mainBowerFiles()
        .pipe jsFilter
        #.pipe output { destination: 'bower.text'}

    vendorScripts = gulp.src './vendor/**/*.js'

    scripts = merge(bowerScripts, vendorScripts)
        .pipe plumber()
        #.pipe output { destination: 'js.text'}
        .pipe flatten()
        .pipe order([
            'modernizr.js'
            'perfnow.js'
            'jquery.js'
            'localforage.js'
            'angular.js'
            'angular-resource.js'
            'angular-cookies.js'
            'angular-*.js'
            'ace.js'
            'highcharts.js'
            'd3.js'
            'ng-google-chart.js'
            'moment.js'
            '**'
        ])
        .pipe concat 'vendor.js'
        .pipe gulp.dest './_public/js'

    webWorkerScripts = gulp.src mainBowerFiles()
        .pipe webWorkerFilter
        .pipe flatten()
        .pipe gulp.dest './_public/js'

    merge(scripts, webWorkerScripts)

gulp.task 'vendor-fonts', ->
    fontFilter = filter ['**/*.eot', '**/*.woff*', '**/*.svg', '**/*.ttf']

    gulp.src mainBowerFiles()
        .pipe fontFilter
        .pipe flatten()
        .pipe gulp.dest './_public/fonts'

gulp.task 'vendor-img', ->
    imgFilter = filter ['**/*.png', '**/*.gif']

    gulp.src mainBowerFiles()
        .pipe imgFilter
        .pipe flatten()
        .pipe gulp.dest './_public/img'

gulp.task 'vendor', gulp.series(
    'bower-install', 
    gulp.parallel('vendor-fonts', 'vendor-scripts', 'vendor-styles', 'vendor-img')
)

gulp.task 'assets', ->
    gulp.src './app/assets/**/*.*'
        .pipe plumber()
        .pipe gulp.dest './_public'

gulp.task 'pug', ->
    gulp.src './app/**/*.pug'
        .pipe plumber()
        .pipe pug { pretty: true }
        .pipe gulp.dest './_public'

gulp.task 'scripts', ->
    # Special handling for config files
    configs = gulp.src './app/scripts/config/*.coffee'
        .pipe plumber()
        .pipe coffee coffeeOptions
        .pipe ngAnnotate ngAnnotateOptions
        .pipe gulp.dest './_public/js/conf'

    merged = merge(configs)

    # Slurp the rest
    slurp = (files, dest, annotate) ->
        coffeeFilter = filter '**/*.coffee', { restore: true }
        slurpPipe = gulp.src files
            .pipe plumber()
            .pipe coffeeFilter
            .pipe coffee coffeeOptions
            .pipe coffeeFilter.restore

        if annotate == true
            slurpPipe = slurpPipe.pipe(ngAnnotate(ngAnnotateOptions))

        merged.add(slurpPipe
            .pipe concat dest
            .pipe gulp.dest './_public/js')

    slurp(['./app/scripts/ie8.coffee'], 'ie8.js')

    slurp([
        './app/scripts/common/mixins.coffee'
        './app/scripts/common/app.coffee'
        './app/scripts/common/**/*.coffee'
        './app/scripts/common/**/*.js'
    ], 'app.common.js', true)

    slurp(['./app/scripts/dashboards/**/*.coffee'], 'app.dashboards.js', true)

    slurp([
        './app/scripts/mgmt/**/*.js'
        './app/scripts/mgmt/**/*.coffee'
    ], 'app.mgmt.js', true)

    slurp([
        './app/widgets/**/*.js'
        './app/widgets/**/*.coffee'
    ], 'app.widgets.js', true)

    return merged

gulp.task 'styles', ->
    appCommon = gulp.src './app/styles/common/*.less'
        .pipe plumber(plumberError)
        .pipe less()
        .pipe concat 'css/app.common.css'
        .pipe gulp.dest './_public'

    appDashboards = gulp.src ['./app/styles/dashboards/*.less', '!./app/styles/dashboards/_*.less']
        .pipe plumber(plumberError)
        .pipe less()
        .pipe concat 'css/app.dashboards.css'
        .pipe gulp.dest './_public'

    appMgmt = gulp.src './app/styles/mgmt/*.less'
        .pipe plumber(plumberError)
        .pipe less()
        .pipe concat 'css/app.mgmt.css'
        .pipe gulp.dest './_public'

    themes = gulp.src './app/styles/themes/*.less'
        .pipe plumber(plumberError)
        .pipe less()
        .pipe rename {
            prefix: 'app.themes.'
        }
        .pipe gulp.dest './_public/css'

    merge(appCommon, appDashboards, appMgmt, themes)

gulp.task 'lint', ->
    gulp.src './app/**/*.coffee'
        .pipe coffeelint(coffeelintOptions)
        .pipe coffeelint.reporter()

gulp.task 'minify', ->
    # Minify all js files
    js = gulp.src './_public/**/*.js'
        .pipe uglify()
        .pipe gulp.dest './_public'

    # Minify all css files
    css = gulp.src './_public/**/*.css'
        .pipe cleanCss()
        .pipe gulp.dest './_public'

    return merge(js, css)

gulp.task 'watch', ->
    gulp.watch 'app/assets/**/*', gulp.parallel('assets')
    gulp.watch 'app/**/*.pug', gulp.parallel('pug')
    gulp.watch 'app/**/*.less', gulp.parallel('styles')
    gulp.watch 'app/**/*.coffee', gulp.parallel('scripts')

gulp.task 'webserver', ->
    confFolder = '_public/js/conf'

    if !fs.existsSync(confFolder + '/configService.js')
        gulp.src confFolder + '/sample.configService.js'
            .pipe rename 'configService.js'
            .pipe gulp.dest confFolder

    connect.server {
        root: '_public'
        livereload: false
        host: '0.0.0.0'
        port: 8080
        https: false
        fallback: path.resolve('./_public/index.html')
        open: 'http://localhost:8080'
    }

gulp.task 'karma', (done) ->
    new karma.Server({
        configFile: __dirname + '/test/karma-unit.conf.coffee'
        singleRun: true
    }, () => done()).start()

gulp.task 'test', gulp.series('scripts', 'karma')

gulp.task 'build', gulp.parallel('vendor', 'assets', 'pug', 'styles', 'scripts')

gulp.task 'server', gulp.series('build', gulp.parallel('watch', 'webserver'))

gulp.task 'production', gulp.series('clean', 'build', 'karma', 'minify')

gulp.task 'default', gulp.series('build')
