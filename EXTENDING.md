# Extending Cyclotron

This guide details some of the ways that Cyclotron can be extended via code: new Widgets, Themes, etc.  This assumes that you are able to build and run
Cyclotron locally&mdash;instructions for this are located in the main `README.md` file.

Completing any of these tasks requires rebuilding the website.  Adding and removing files may not work correctly with `gulp server`, so you may need to stop and restart gulp to perform a complete build.

## Adding a Widget

Widgets are contained in the `app/scripts/widgets/` folder.  Each Widget requires a few things:

* Properties defined in `app/scripts/common/services/services.commonConfigService.coffee`
* Jade template
* Angular.js controller
* Less Stylesheet
* Help page

Some of these are actually optional, but most Widgets will need all of them.  In most cases it's best to follow the conventions of other Widgets, so consider using one of them as a template (e.g. HTML Widget)

1. Create a subfolder under the `app/scripts/widgets/` folder, with the same name as the Widget

2. Add a new Jade template to this folder, named `<widget>.jade`.  This is the main view of the Widget.

3. Add a new Jade template named `help.jade`.  This file will be loaded automatically into the Help section of Cyclotron, and should be filled out with description, information, and examples.

4. If a Angular.js controller is needed, add a new `*.coffee` file and reference it from the Jade template:

        .html-widget(ng-controller='HtmlWidget')

    The values of Widget properties will be available via `$scope.widget.<propertyName>` in the Controller.

5. Add a new Less stylesheet, `_*.less`.  The underscore prefix prevents it from being compiled automatically with the rest of the styles&mdash;this is important for themes.  It's advised to nest all styles for the widget underneath a parent class to avoid affecting other components:
    
        .html-widget {
            /* Styles here */
        }

    Make sure the class name matches between the stylesheet and the Jade template.  

6. Document the Widgets properties in `app/scripts/common/services/services.commonConfigService.coffee`. Under `exports.widgets`, add a new key/value pair for the new Widget.  For example:

        ...
        exports = {
            ... 

            widgets:
                ...

                myNewWidget:
                    name: 'myNewWidget'
                    icon: 'fa-rocket'
                    properties:
                        property1:
                            label: 'Property One'
                            description: 'This is a new property'
                            type: 'string'
                            required: false
                            order: 10
                        ...
        }

    Ensure that the new Widget's folder name matches the widget's key and name property here, as these are used to automatically load the Widget.

7. Edit each Theme in `app/styles/themes`.  At the bottom of each Theme file is a section of `@import` statements that load each Widget's stylesheet:

        @import "../../widgets/html/_html.less";

    Add a new line in each Theme to import the new Widget's stylesheet.

8. Optionally, Angular.js directives may be needed to implement some of the Widget functionality.  They should be put in the same Widget folder, and they will
be loaded automatically.

## Removing a Widget

Don't want a Widget anymore?  It's easy to remove, and will reduce the amount of unneeded resources loaded with each Dashboard:

1. To prevent the Widget from being a dropdown option in the Dashboard Editor, edit `app/scripts/common/services/services.commonConfigService.coffee`. Under `exports.widgets`, remove the appropriate key/value.

2. In `app/scripts/widgets`, delete the Widget's entire folder.

## Adding a Data Source

Data Sources are Cyclotron's interface to external services or databases.  They encapsulate the implementation of how to connect and retrieve data, and expose certain properties for configuration.  Since Cyclotron runs in the browser, Data Sources are essentially limited to what browsers can connect to; namely other web services.  The JSON Data Source is fairly generic and can be used to connect to most things, but it may be convenient to add new Data Sources that wrap up the configuration for some target system.

The easiest solution is to extend the DataSourceFactory; this is the most common approach in Cyclotron.  This handles most of the built-in functionality, allowing a custom Data Source to only implement the key method of getting and returning data.

1. Create a new file in `app/scripts/dashboards/dataSources`.  It is recommended to copy and modify an existing Data Source, for example `dataSources.json.coffee`

2. Update the Data Source name:

        cyclotronDataSources.factory 'jsonDataSource', ...

3. Update the call to the Data Source Factory with the new name:

        dataSourceFactory.create 'JSON', runner

4. The `runner` method implements the logic for the Data Source.  Its argument is `options`, containing all the properties the Data Source was configured with.  It should return a promise, which is resolved with data or rejected with an error.  Here's a simple example:

        runner = (options) ->

            q = $q.defer()

            req = $http.post options.url, options.request
            
            # Add callback handlers to promise
            req.success (result) ->
                q.resolve({ '0': data: result.body, columns: null })
            req.error (error) -> 
                q.reject(error)

            return q.promise

5. Data Sources can optionally return multiple result sets.  The default result set name is '0', as shown above.  If multiple result sets are returned from a single execution, the object above can have multiple key/value pairs, one for each result set.  If columns are not returned by the Data Source, it should be set to null.

6. Some of the built-in Data Sources proxy all requests through the Cyclotron service, but this is not a requirement.  It may be useful for getting around Cross-Origin Resource Sharing restrictions which may prevent some web services from being accessible directly through a browser.  

7. Add a new Help page in `app/partials/help/datasources`, with the same name as the Data Source.  It will be linked automatically.

8. In order for the new Data Source to appear in the Dashboard Editor, it must be added to the configuration file. Open `app/scripts/commmon/services/services.commonConfigService.coffee` and edit the section under `exports.dashboard.properties.dataSources.options`.  Add a new key/value pair with the same key name as the new Data Source, and set its values similar to existing Data Sources.  Define any configurable properties that an end-user can modify, with optional default values.

9. Environment-specific configuration overrides can be applied in `configService.coffee`.  We use this file to apply default server names or URLs, which may be different between environments.  These changes must be made in the compiled config file, located in `_public/js/conf/configService.js`.  The structure is the same&mdash;this file extends the settings in `services.commonConfigService.coffee`.

## Adding a Theme

Themes provide a consistent set of styling for all Widgets.  At the most basic level, they control the Dashboard background and the borders of Widgets, but they also provide variables (or overrides) for Widget styling.

1. Add a new file in `app/styles/themes`.  It is recommended to copy and modify an existing theme, for example `light.less`.

2. Modify the theme as desired.  Variables defined in the themes are used again in the Widget stylesheets, so changing them can quickly alter the look of a Dashboard.  Page and Widget border styles are defined directly in the theme.

3. Make sure to import each Widget's stylesheet within the new theme, similarly to existing themes.

4. In order for the new theme to appear in the Dashboard Editor, it must be added to the configuration file. Open `app/scripts/commmon/services/services.commonConfigService.coffee` and edit the section under `exports.dashboard.properties.themes`.  Add a new key/value pair with the same key name as the new theme, and set the `value` and other properties accordingly.

5. The Chart Widget applies themes via JSON, so open `app/scripts/commmon/services/services.commonConfigService.coffee` and edit the section under `exports.widgets.chart.themes`. Add a new key/value pair with the same key name as the new theme.  This is best copied from an existing theme and modified as desired.  These properties are applied to a Highcharts chart&mdash;[documentation here](http://api.highcharts.com/highcharts).
