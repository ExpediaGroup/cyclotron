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

cyclotronServices.factory 'loadService', (configService, $rootScope) ->
    {
        setTitle: (title) ->
            $rootScope.page_title = title

        removeLoadedCss: ->
            $('.loadServiceAsset.temporary').remove()

        loadCssUrl: (url, permanent = false) ->
            link = document.createElement("link")
            link.type = "text/css"
            link.rel = "stylesheet"
            link.href = url
            link.className = 'loadServiceAsset'
            if !permanent then link.className += ' temporary'

            document.getElementsByTagName("head")[0].appendChild(link)

                # loadCssFile: Helper that loads a CSS file

        loadCssInline: (css, permanent = false) ->
            style = document.createElement("style")
            style.type = 'text/css'
            style.className = 'loadServiceAsset'
            if !permanent then style.className += ' temporary'

            if style.styleSheet
                style.styleSheet.cssText = css
            else
                style.appendChild document.createTextNode(css)

            document.head.appendChild(style)
    }
