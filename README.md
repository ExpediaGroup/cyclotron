# Cyclotron

Cyclotron is a browser-based platform for creating dashboards.  It provides standard boilerplate and plumbing, allowing non-programmers to easily create and edit dashboards using customizable components.  It has a built-in dashboard editor, and hosts the dashboards directly.

Dashboards are defined declaratively as a JSON document, which contains all the properties required to render the Dashboard.

## Contents

- [Key Concepts](#key-concepts)
- [Features](#features)
- [Should I Use Cyclotron?](#should-i-use-cyclotron)
- [Requirements](#requirements)
- [Installation](#installation)
     - [MongoDB](#mongodb)
     - [Node.js](#nodejs)
     - [REST API](#rest-api)
     - [Website](#website)
- [Deployment](#deployment)
- [Extending Cyclotron](#extending-cyclotron)
- [Contributing](#contributing)
- [Licensing](#licensing)

## Key Concepts

* _Dashboard_: a series of Pages, as well as Data Sources, Scripts, Styles, and other configurations; stored as a JSON document, it contains all the properties required to render itself

* _Page_: one or more Widgets combined in various sizes and layout; one Page is displayed at a time

* _Widget_: reusable component that displays on the Dashboard; different types are available

* _Data Source_: reusable component that retrieves data for use by Widgets; different types are available

## Features

* Declarative definition of Dashboards, requiring no HTML or JavaScript (although it's optionally available)

* Included Widgets: Annotation Chart, Chart, Header, HTML, iFrame, Image, Javascript, JSON, Number, QRCode, Stoplight, Table, Treemap, Youtube

* Included Data Sources: CyclotronData, Elasticsearch, Graphite, InfluxDB, Javascript, JSON, Prometheus, Splunk

* Built-in data loading, filtering, and sorting

* LDAP/Active Directory Integration

* Permissions for viewing and editing Dashboards

* Built-in analytics for Dashboards

* Mobile support

* REST API access

## Should I Use Cyclotron?

Cyclotron is best thought of as an alternative to custom, light-weight websites that visualize data. It provides the web hosting, page layout, data loading, and assorted widgets—all without writing code. In contrast, building a comparable website from scratch would require provisioning a server/VM, choosing the appropriate web frameworks and libraries, and writing the code for the site. Cyclotron simplifies this process dramatically, making it ideal for rapid prototyping.

However, Cyclotron has a limited set of built-in Widgets and Data Sources.  The HTML and JavaScript Widgets do allow for a wide degree of customization, but require some web development.  Cyclotron lacks built-in interactivity, so it may not be ideal for building highly interactive websites.  Additionally, it is designed for building full-screen dashboards, not reports.

In regards to data, Cyclotron does not store or cache any data for Dashboards. Dashboards can load external data through various Data Sources, but it is done on-the-fly when Dashboards are viewed.  Cyclotron can do filtering/sorting and custom transformations, but this should not be considered a replacement for ETL jobs.  In this regard, Cyclotron is ideal as a front-end for an existing database or web service.

## Requirements

* Node.js
    * Requires >= 6.x to run `cyclotron-site` tests
    * Requires >= 0.10 to run
* MongoDB (2.6+)
* (Optional) Any web server--Nginx, Apache, IIS, etc

Node.js and MongoDB are available on Linux, OS X, and Windows, so it should be possible to run Cyclotron on any of these platforms, although the specific steps may vary.

MongoDB 2.6 or above is required to use all functionality of the service.

## Installation

These installation instructions are primarily intended for development and testing purposes.  Refer to the Deployment section for more details on server deployment.

Start by cloning this git repository locally onto your computer.  If you don't have git installed, GitHub has a nice guide: [Set Up Git](https://help.github.com/articles/set-up-git/).  On Windows, [GitHub for Windows](https://windows.github.com/) is an easy way to install git.

Alternatively, download a ZIP archive of the repository contents and extract it.

### MongoDB

Install MongoDB according to the [installation instructions](http://docs.mongodb.org/manual/installation/) for your system. Cyclotron automatically creates the MongoDB database on startup MongoDB server, so no other configuration needs to be done.

MongoDB does not have to be installed on the same system as the Cyclotron website or service, as long as the connection property is updated accordingly.  Replica sets and authentication are also supported.

Ensure MongoDB is running before continuing:

    mongod --config /usr/local/etc/mongod.conf


### Node.js

Install the latest stable version of [Node.js](http://nodejs.org/) for your system.  This should install [npm](https://www.npmjs.com/) as well.

Packages may be available separately for your system, depending on the OS and package manager.

### REST API

The `cyclotron-svc/` folder contains the REST API for Cyclotron, which interfaces with MongoDB.

1. Open the `cyclotron-svc/` folder in the shell

2. Install dependencies using [npm](https://www.npmjs.com/):

        npm install

    **Windows**: this may need to be run as an Administrator.  Open the Node.js Command Prompt as an Administrator and run the command there.

    **Windows/OSX/Linux**: node-gyp may require certain dependencies to be installed.  See platform-specific instructions [here](https://github.com/nodejs/node-gyp#installation).

3. Create a configuration file at `cyclotron-svc/config/config.js`.  A sample configuration file `sample.config.js` is provided:

        cp config/sample.config.js config/config.js

    The sample config defaults to using a local MongoDB instance, with authentication disabled.  If using a remote MongoDB server or cluster, update the `mongodb` property accordingly.

    If using Active Directory or LDAP, ensure that the property `enableAuth` is set to true, and that all the `ldap` properties are filled in correctly, including the service account username and password used to validate logins.

4. Start the service in node:

        node app.js

5. To verify the service is running, open the API documentation in a browser at [http://localhost:8077]()

For more information on the REST API and its configuration, please refer to [cyclotron-svc/README.md](cyclotron-svc/README.md).

### Website

The `cyclotron-site/` folder contains the website for Cyclotron.

1. Open the `cyclotron-site/` folder in the shell

2. Install all dependencies using [npm](https://www.npmjs.com/):

        npm install

    **Windows**: this may need to be run as an Administrator.  Open the Node.js Command Prompt as an Administrator and run the command there.

3. Install [Gulp](http://gulpjs.com/) globally.  This is the build system for the website, and only has to be done once.

        npm install --global gulp

    **Windows/Linux/OSX**: this may need to be run as an Administrator or with sudo privileges.

4. Build and run the service:

        gulp server

    This compiles the website into the `_public` folder and starts a local development web server.  The website should automatically open: [http://localhost:8080]().

    **"unable to connect to github.com"**: this may be due to a firewall blocking the *git://* protocol.  Run this:

        git config --global url."https://".insteadOf git://

    **Windows**: Git must be in the PATH to successfully build the website; if using GitHub for Windows, just open the Git Shell which automatically adds it.

5. Update the configuration file at `_public/js/conf/configService.js` as needed.  Gulp automatically populates this file from `sample.configService.js` if it does not exist.

    The sample config defaults to using a local cyclotron-svc instance, with authentication disabled.  If authentication has been enabled in the REST API, it must be enabled in this config as well.

For more information on the Cyclotron website, please refer to [cyclotron-site/README.md](cyclotron-site/README.md).

## Deployment

For specific details on deployment, please refer to [cyclotron-site/README.md](cyclotron-site/README.md) and [cyclotron-svc/README.md](cyclotron-svc/README.md).

## Extending Cyclotron

More information on extending Cyclotron is available in [EXTENDING.md](EXTENDING.md)

## Contributing

We gladly accept contributions to Cyclotron in the form of issues, feature requests, and pull requests!  Check out [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Licensing

Cyclotron is licensed under the MIT license; refer to [LICENSE](LICENSE) for the complete text.

Cyclotron has a dependency on [Highcharts](http://www.highcharts.com/), a commercial JavaScript charting library.  Highcharts offers both a commercial license as well as a free non-commercial license.  Please review the [licensing options and terms](https://shop.highsoft.com/highcharts.html) before using this software, as the Cyclotron license neither provides nor implies a license for Highcharts.

The only feature depending on Highcharts is the Chart widget, so both can be removed if necessary.
