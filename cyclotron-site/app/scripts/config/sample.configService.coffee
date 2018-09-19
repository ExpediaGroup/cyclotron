#
# Sample Config File
#
# This file is a sample configuration file for Cyclotron.  It is configured for a local instance
# of the Cyclotron REST API (cyclotron-svc), so it can be used as-is.
# 
# Post-build, this file will be found in the `_public/js/conf/` folder.
# Cyclotron attempts to load a file named `configService.js`, so this file must be renamed or
# copied prior to use.
#
# By default, the development task `gulp server` will copy this file if `configService.js` does not
# already exist.
#
# This configService depends on the 'commonConfigService', found in `scripts/common/services`.
# Most of the configuration is done in that service, and this service merely wraps it, providing
# environment-specific configs.  This facilitates deploying multiple Cyclotron environments, 
# where only the endpoints are different.
#
cyclotronServices.factory 'configService', (commonConfigService) ->

    # List of neighboring Cyclotron instances
    # Used for:
    #   1) Push Dashboard to Environment (e.g. push from Dev to Prod)
    #   2) Data Source Proxying
    #
    # "name": Display Name.
    # "serviceUrl": Destination service endpoint.
    # "requiresAuth": Must match the configuration on the destination service.
    # "canPush": If true, enables pushing Dashboard from this instance to the destination instance.
    #
    cyclotronEnvironments = [
        {
            name: 'Dev'
            serviceUrl: 'http://cyclotron/api'
            requiresAuth: true
            canPush: true
        }
        {
            name: 'Localhost'
            serviceUrl: 'http://localhost:8077'
            requiresAuth: false
            canPush: false
        }
    ]

    # Convert cyclotronEnvironments into the correct format for property options
    proxyOptions = _.reduce cyclotronEnvironments, (options, environment) ->
        options[environment.name] = { value: environment.serviceUrl }
        return options
    , {}

    exports = 
        # Cyclotron-svc endpoint
        restServiceUrl: 'http://localhost:8077'

        authentication:
            # Enable or disable authentication
            # Should match the cyclotron-svc configuration
            enable: false

            # Message displayed when logging in.  Set to null/blank to disable
            loginMessage: 'Please login using your LDAP username and password.'

            # If true, the user's password will be encrypted and cached in the browser
            # This allows data sources to authenticate with the current user's credentials
            cacheEncryptedPassword: false

        # Analytics settings
        analytics:
            # Enable or disable analytic tracking for dashboards
            enable: false

        # Logging settings
        logging:
            enableDebug: false

        # New Users
        newUser:
            # Enables/disables welcome message for new users
            enableMessage: true

        
        # List of neighboring Cyclotron instances
        cyclotronEnvironments: cyclotronEnvironments

        # Changelog location, displayed on the home page footer
        #changelogLink: 'https://.../CHANGELOG.md'

        # Overrides for Dashboard properties
        #
        # 1) Provide environment-specific default values, e.g. default URLs for Data Sources
        # 2) Set proxy options for Data Sources
        #
        dashboard:
            properties:
                dataSources:
                    options:
                        cyclotronData:
                            properties:
                                url:
                                    options: proxyOptions
                        graphite:
                            properties:
                                url:
                                    # The default Graphite hostname, so it does not need to be specified in each Dashboard
                                    # (Remove if there is no appropriate default)
                                    default: 'http://sampleGraphiteHost:80'
                                proxy:
                                    options: proxyOptions
                        json:
                            properties:
                                proxy:
                                    options: proxyOptions
                        prometheus:
                            properties:
                                proxy:
                                    options: proxyOptions
                        splunk:
                            properties:
                                host:
                                    # The default Splunk hostname, so it does not need to be specified in each Dashboard
                                    # (Remove if there is no appropriate default)
                                    default: 'splunk'
                                proxy:
                                    options: proxyOptions

        # Add additional logos to the Dashboard Sidebar 
        dashboardSidebar:
            footer:
                logos: [{
                    title: 'Cyclotron'
                    src: '/img/favicon32.png'
                    href: '/'
                }]

    # Merge overrides with commonConfigService
    # Settings in this file will override/extend those in the commonConfigService
    merged = _.merge(commonConfigService, exports, _["default"])

    # Add a custom welcome message to the Help page
    # Additional messages can be added, e.g. support mailing list
    merged.help[0].messages = [{
        type: 'info',
        html: 'Welcome to Cyclotron!',
        icon: 'fa-info-circle'
    }];

    return merged;
