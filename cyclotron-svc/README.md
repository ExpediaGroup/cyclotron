# Cyclotron-svc

This folder contains the REST API for Cyclotron.  It is a [Node.js](http://nodejs.org/) application, built with [Express](http://expressjs.com/).  Data is stored in [MongoDB](http://www.mongodb.org/) using the [Mongoose](http://mongoosejs.com/) library.

## Installation

Refer to the installation instructions in the parent [README.md](../README.md).

## Configuration

The service configuration is located in `config/config.js`.  This file is missing by default, but there are sample templates in the same folder which can be copied and used.  The service will not start without the config file in place.

The available configuration properties are documented in `config/sample.config.js'. This config file can be used as-is to connect to a local MongoDB server, or used as a starting point for a new configuration.

## Deployment

Deploying Cyclotron on a server is dependent on the OS. The primary concern is running the web service as a daemon instead of a user account.  Included in the `cyclotron-svc/init.d/` folder is a sample sysvinit script which can be used in many flavors of Linux.

1. Install Node.js and npm

2. Install the cyclotron-svc files onto the server, for example: `/opt/app/cyclotron-svc`

3. Create the configuration file in `/opt/app/cyclotron-svc/config/`

4. Copy the `cyclotron-svc/init.d/cyclotron-svc` script to `/etc/init.d/cyclotron-svc`

5. Install forever globally via npm:

        npm install -g forever

    Forever is used to restart the service if it crashes.

6. Install PhantomJS and CasperJS globally via npm:

        npm install -g phantomjs
        npm install -g casperjs

    These packages are used to export Dashboards to PDFs.

7. Create the `log/` and `export/` folder and grant permissions

8. Start the service via init.d:

        sudo service cyclotron-svc start

9. Enable auto-run on system start:

        sudo chkconfig cyclotron-svc on

These steps may vary for different operating systems.
