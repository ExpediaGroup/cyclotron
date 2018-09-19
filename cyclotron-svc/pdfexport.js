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
 
 /* Cyclotron Export Script via CasperJS (http://docs.casperjs.org/en/latest/installation.html)
 *
 *  Sample usage: casperjs pdfexport.js http://cyclotron/<dashboardName> uniqueId
 */

var casper = require("casper").create({
    verbose: true,
    logLevel: "debug",
    viewportSize: {
        width: 1220,
        height: 915
    }
});

var firstPage = true;
var images = [];
var dashboardUrl = casper.cli.args[0];
var id = casper.cli.args[1];
var outputDirectory = 'export/';

console.log('Id: ' + id);

/* helper to hide some element from remote DOM */
casper.hide = function(selector) {
    this.evaluate(function(selector) {
        document.querySelector(selector).style.display = "none";
    }, selector);
};

var timeout = 600000;
var timeoutFn = function() {
    this.die("Page timeout reached.");
    this.exit();
}

casper.on('remote.message', function(message) {
    this.echo('LOG ' + message);
});

var next = function() {
    this.waitForSelector('div.dashboard-pages', function afterPageLoad () {
        this.echo('-- Page Loaded --');

        this.waitWhileSelector(".spinner", function afterDataLoad () {
            this.echo('-- Spinners Gone --');
            this.zoom(1);

            this.wait(1220, function() {

                var currentPage = this.getElementAttribute('div.dashboard-page', 'page-number') || 0;
                console.log('-- Current Page: ' + currentPage + ' --');

                if (firstPage === true || currentPage != 0) {
                    firstPage = false;

                    var image;
                    this.evaluate("$('i.widget-fullscreen').hide()");
                    this.evaluate("$('.table-widget i.fa-sort-up').hide()");
                    this.evaluate("$('.table-widget i.fa-sort-down').hide()");
                    this.evaluate("$('.dashboard').addClass('dashboard-export')");
                    this.evaluate("$('.dashboard .dashboard-widgetwrapper>.dashboard-widget').addClass('widget-noscroll')");

                    image = outputDirectory + id + '-' + currentPage + '.png';
                    images.push(image);

                    this.echo("Processing page " + currentPage + ": " + this.getCurrentUrl());
                    this.captureSelector(image, 'html');

                    /* Move to the next page */
                    this.click('i.fa.fa-chevron-right');

                    currentPage++;
                    casper.then(next);
                } else {
                    this.then(buildPdf);
                }
            });
        }, timeoutFn, timeout);
    }, timeoutFn, 10000);
};

/* Building resulting page, image, and pdf */
var buildPdf = function() {
    var fs, pageHtml;
    this.echo("Build result page");
    fs = require("fs");
    pageHtml = "<html><body style='background:white;margin:0;padding:0;width:1220'>";

    images.forEach(function(image) {
        pageHtml += "<img src='file:///" + fs.workingDirectory + "/" + image + "'><br>";
    });

    pageHtml += "</body></html>";

    var htmlFile = outputDirectory + id + '.html';
    var pdfFile = outputDirectory + id + '.pdf';
    fs.write(htmlFile, pageHtml, 'w');

    this.thenOpen(htmlFile, function() {
        this.viewport(1220, 915).then(function() {
            this.echo("Resulting image saved to " + pdfFile);
            this.zoom(.75);
            casper.page.paperSize = {
                width: '1220px',
                height: '915px',
                orientation: 'landscape',
                border: '0'
            };

            this.captureSelector(pdfFile, "html");
            this.exit();
        });
    });
};

casper.start(dashboardUrl);
casper.then(next);
casper.run();
