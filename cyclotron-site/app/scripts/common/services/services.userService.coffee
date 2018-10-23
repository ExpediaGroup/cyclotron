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

cyclotronServices.factory 'userService', ($http, $localForage, $q, $rootScope, $window, configService, cryptoService, logService) ->

    loggedIn = false
    currentSession = null

    exports = {
        authEnabled: configService.authentication.enable

        cachedUserId: null

        cachedUsername: null

        cachedPassword: null

        isLoggedIn: -> 
            return true unless configService.authentication.enable
            loggedIn && currentSession?

        isAdmin: -> currentSession?.user?.admin == true

        currentSession: -> currentSession

        currentUser: -> currentSession?.user

        setLoggedOut: ->
            loggedIn = false
            currentSession = null
            exports.cachedPassword = null
            $localForage.removeItem('session')
            $localForage.removeItem('cachedPassword')

            if $window.Cyclotron?
                $window.Cyclotron.currentUser = null
                $window.Cyclotron.currentUsername = null
                $window.Cyclotron.currentUserPassword = null

            return

        isNewUser: true

        notNewUser: (update = true) ->
            return unless exports.isNewUser

            # Save flag indicating this is no longer a new user
            $localForage.setItem('newUser', 0).then ->
                # Change field accordingly 
                exports.isNewUser = false if update
                logService.debug 'User is not longer a New User'

    }

    # Load cached username
    $localForage.getItem('username').then (username) ->
        if username?
            exports.cachedUsername = username
            if $window.Cyclotron?
                $window.Cyclotron.currentUsername = username

    # Load cached userId (not UID)
    $localForage.getItem('cachedUserId').then (userId) ->
        if userId?
            exports.cachedUserId = userId

    # Load cached user password (encrypted)
    $localForage.getItem('cachedPassword').then (cachedPassword) ->
        if cachedPassword? and configService.authentication.cacheEncryptedPassword
            exports.cachedPassword = cachedPassword
            if $window.Cyclotron?
                $window.Cyclotron.currentUserPassword = cachedPassword

    # Load New User quality
    $localForage.getItem('newUser').then (value) ->
        if value == 0
            logService.debug 'User is definitely not a New User'
            exports.isNewUser = false
        else if value > 0
            logService.debug 'User is definitely a New User'
        else
            logService.debug 'User is probably a New User'
            $localForage.setItem 'newUser', 1

    exports.login = (username, password) ->
        return if _.isEmpty(username) || _.isEmpty(password)

        post = $http.post(configService.restServiceUrl + '/users/login',
            { username, password })

        deferred = $q.defer()

        post.success (session) ->
            currentSession = session
            
            # Store session and username in localstorage
            $localForage.setItem 'session', session
            $localForage.setItem 'username', username
            $localForage.setItem 'cachedUserId', session.user._id
            exports.cachedUsername = username
            exports.cachedUserId = session.user._id

            loggedIn = true

            $rootScope.$broadcast 'login', { }
            if $window.Cyclotron?
                $window.Cyclotron.currentUsername = username
                $window.Cyclotron.currentUser = session.user
            
            alertify.success('Logged in as <strong>' + session.user.name + '</strong>', 2500)

            if (configService.authentication.cacheEncryptedPassword)
                # Encrypt and cache the password for use in data sources
                cryptoService.encrypt(password).then (encrypedPassword) ->
                    $localForage.setItem 'cachedPassword', encrypedPassword
                    exports.cachedPassword = encrypedPassword
                    if $window.Cyclotron?
                        $window.Cyclotron.currentUserPassword = encrypedPassword

                    deferred.resolve(session)
            else 
                
                deferred.resolve(session)
            

        post.error (error) ->
            exports.setLoggedOut()
            deferred.reject(error)

        return deferred.promise

    exports.loadExistingSession = (hideAlerts = false) ->
        return currentSession if currentSession?

        deferred = $q.defer()
        errorHandler = ->
            exports.setLoggedOut()
            deferred.resolve(null)

        if configService.authentication.enable == true

            $localForage.getItem('session').then (existingSession) ->

                if existingSession?
                    validator = $http.post(configService.restServiceUrl + '/users/validate', { key: existingSession.key })
                    validator.success (session) ->
                        currentSession = session
                        loggedIn = true
                        if $window.Cyclotron?
                            $window.Cyclotron.currentUser = session.user

                        alertify.log('Logged in as <strong>' + session.user.name + '</strong>', 2500) unless hideAlerts
                        deferred.resolve(session)

                    validator.error (error) ->
                        exports.setLoggedOut()
                        alertify.log('Previous session expired', 2500) unless hideAlerts
                        errorHandler()
                else
                    errorHandler()
            , errorHandler
        else
            errorHandler()

        return deferred.promise

    exports.logout = ->
        deferred = $q.defer()

        if currentSession?
            promise = $http.post(configService.restServiceUrl + '/users/logout', { key: currentSession.key })
            promise.success ->
                exports.setLoggedOut()
                
                $rootScope.$broadcast('logout')
                alertify.log('Logged Out', 2500)
                deferred.resolve()

            promise.error (error) ->
                alertify.error('Error during logout', 2500)
                deferred.reject()

        return deferred.promise

    exports.search = (query) ->

        deferred = $q.defer()

        promise = $http.get(configService.restServiceUrl + '/ldap/search', { params: { q: query } })
        promise.success (results) ->
            deferred.resolve(results)
        promise.error (error) ->
            logService.error('UserService error: ' + error)
            deferred.reject()
            
        return deferred.promise

    exports.hasEditPermission = (dashboard) ->
        return true unless configService.authentication.enable

        # Non-authenticated users cannot edit
        return false unless exports.isLoggedIn()

        # User is Admin
        return true if exports.isAdmin()

        # No edit permissions defined
        return true if _.isEmpty(dashboard?.editors)

        # User is in the editors list, or they are a member of a group that is
        return _.any dashboard.editors, (editor) ->
            return (currentSession.user.distinguishedName == editor.dn) || 
                _.contains(currentSession.user.memberOf, editor.dn)

    exports.hasViewPermission = (dashboard) ->
        return true unless configService.authentication.enable

        # Assume non-authenticated users can view
        return true unless exports.isLoggedIn()

        # User is Admin
        return true if exports.isAdmin()

        # No view permissions defined
        return true if _.isEmpty(dashboard?.viewers)

        # If user can edit, they can view
        return true if exports.hasEditPermission(dashboard)

        # User is in the viwers list, or they are a member of a group that is
        return _.any dashboard.viewers, (viewer) ->
            return (currentSession.user.distinguishedName == viewer.dn) || 
                _.contains(currentSession.user.memberOf, viewer.dn)

    exports.likesDashboard = (dashboard) ->
        return false unless configService.authentication.enable
        
        # Must be logged in to like a dashboard
        return false unless exports.isLoggedIn()

        return _.contains dashboard.likes, currentSession.user._id

    return exports
