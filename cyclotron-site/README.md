# Cyclotron-site

This folder contains the website for Cyclotron.  It is an [Angular.js](http://angularjs.org/) single-page application, written in [Coffeescript](http://coffeescript.org/), with [Jade](http://jade-lang.com/) templates and [Less](http://lesscss.org/) stylesheets.

[Gulp](http://gulpjs.com/) is used to compile all the assets.  It can also run tests, start a web server, minify files, etc.  See below for details.

## Installation

Refer to the installation instructions in the parent [README.md](../README.md).

## Gulp

[Gulp](http://gulpjs.com/) is a Node.js-based build system and task runner.  The configuration is defined in `gulpfile.coffee`.

The installation instructions recommend installing Gulp globally using `npm`.  This is not required thanks to [`npx`](https://blog.npmjs.org/post/162869356040/introducing-npx-an-npm-package-runner).  The following are equivalent:

    gulp build
    npx gulp build
    npm run build
    ./node_modules/.bin/gulp build

The following `npm` tasks

    npm run build           # Builds website
    npm start               # Starts developement server
    npm test                # Runs unit tests

### Gulp Tasks

This project has several Gulp tasks configured in `gulpfile.coffee`:

* Rebuilds all project files into the `_public` directory:

        gulp build

* Watches for file changes and automatically reruns the affected portions of the build:

        gulp watch

* Builds the project and starts a development web server:

        gulp server

    This compiles the website into the `_public` folder and starts a local development web server at [http://localhost:8080]().  It combines the tasks `build`, `watch`, and `webserver`.

* Deletes the `_public` folder for a clean build:

        gulp clean

* Rebuilds Coffeescript files, and runs automated tests:

        gulp test

    This task includes a rebuild of scripts to ensure the tests are run on the latest code.  The tests can also be run without doing a build first:

        gulp karma

* Performs a `clean`, `build`, `test`, and `minify`.  Intended for building production releases:

        gulp production

* Runs [CoffeeLint](http://www.coffeelint.org/) on the CoffeeScript files and report any issues:

        gulp lint


## Automated Tests

Unit tests are written with [Karma](https://karma-runner.github.io/3.0/index.html) and [Jasmine](https://jasmine.github.io/), and executed on [PhantomJS](http://phantomjs.org/).  The tests can be run with the following command:

    gulp test

The configuration for the test run is `test/karma-unit.conf.coffee`.  Additional browsers (Chrome, Firefox) can be enabled as well.  Code-coverage reports are generated automatically and are available in `coverage/` after running the tests.

## Dependencies

[Bower](http://bower.io/) is used to pull in third-party dependencies.  These libraries are not included in this repository, but will be automatically downloaded at runtime.  The `bower.json` file lists all the dependencies and versions, as well as overrides for which files to include.

The gulp task `gulp vendor` will invoke Bower and concatenate the libraries into `_public/`.

Adding new dependencies requires Bower to be installed globally:

    npm install --global bower

To add a new dependency, run this command and verify the results:

    bower install --save <libraryname>

Search for Bower packages [here](http://bower.io/search/).

## Configuration

When the website is opened, it loads its configuration from `_public/js/conf/configService.js`. If this file does not exist, `gulp server` automatically populates this file from `sample.configService.js` before starting the server.

The available configuration properties are documented in `app/scripts/config/sample.configService.coffee'.  This config file can be used as-is to connect to a local Cyclotron-svc instance, or used as a starting point for a new configuration.

## Deployment

Deploying Cyclotron on a server is dependent on the OS and web server being used.  Since the entire site is compiled to static assets, any standard web server can host the website (e.g. Nginx, Apache, IIS, etc.).

Since the website is built as a single-page app, all URLs that don't map to a file in the filesystem should serve `index.html`.  This will allow the application to load, and the JavaScript router will render the correct page.

### Nginx Deployment

Included in the repo is `nginx.conf`, which is a sample configuration for [Nginx](http://nginx.org/).

1. Install Nginx, either [manually](http://nginx.org/en/download.html) or via your system's package manager.

2. Create the configuration file, `/opt/app/cyclotron-site/_public/config/config.js`

3. Copy `nginx.conf` to `/etc/nginx/conf.d/cyclotron-site.conf`.

4. Ensure that the main nginx config loads configurations from `/conf.d`

5. Start or restart Nginx:

        sudo service nginx restart

6. Enable Nginx to auto-run on system start:

        sudo chkconfig nginx on

