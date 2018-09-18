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

# Inspired by and adapted from http://bost.ocks.org/mike/treemap/
cyclotronDirectives.directive 'treemap', ($window) ->

    # Determines if white or black will be better contrasting color
    getContrast50 = (hexcolor) ->
        return '#333333' unless hexcolor?.replace?
        if (parseInt(hexcolor.replace('#', ''), 16) > 0xffffff/3) then 'black' else 'white'

    return {
        restrict: 'C'
        scope:
            data: '='
            labelProperty: '='
            valueProperty: '='
            valueFormat: '='
            valueDescription: '='
            colorProperty: '='
            colorDescription: '='
            colorFormat: '='
            colorStops: '='
            showLegend: '='
            legendHeight: '='

        link: (scope, element, attrs) ->

            d3 = $window.d3
            $element = $(element)
            $widgetBody = $element.parent()

            margin = 
                top: 30
                right: 0
                bottom: 0
                left: 0

            # Colors - initialize or reinitialize the color scale
            initializeColors = ->
                # Color
                scope.colorDomain = _.map _.pluck(scope.colorStops, 'value'), parseFloat
                colorRange = _.pluck scope.colorStops, 'color'

                if _.isEmpty(scope.colorProperty) or _.isEmpty(scope.colorStops) or scope.colorStops.length < 2
                    scope.showLegend = false
                    scope.useColor = false
                else 
                    scope.useColor = true

                margin.bottom = if scope.showLegend
                    scope.legendHeight
                else 
                    0
                
                # Color scale 
                scope.colorScale = d3.scale.linear()
                    .domain(scope.colorDomain)
                    .range(colorRange)

            initializeColors()

            width = null
            height = null
            x = null
            y = null

            formatValueNumber = (value) ->
                numeral(value).format(scope.valueFormat)

            formatColorNumber = (value) ->
                numeral(value).format(scope.colorFormat)

            # Initialization
            treemap = d3.layout.treemap()
                .children (d, depth) -> if depth then null else d._children
                .sort (a, b) -> a.value - b.value
                .round false

            svg = d3.select(element[0]).append 'svg'

            svgInner = svg.append 'g'
                .style 'shape-rendering', 'crispEdges'

            grandparent = svgInner.append 'g'
                .attr 'class', 'grandparent'

            header = grandparent.append 'rect'
            headerText = grandparent.append 'text'
            headerIcon = grandparent.append 'text'
                .attr 'class', 'icon'
                .attr 'opacity', 0
                .text '\uf0e2'
            headerIcon.append 'title'
                .text 'Click to return'

            footer = svg.append 'g'
                .attr 'class', 'footer'

            if scope.showLegend
                legend = footer.append 'g'
                    .attr 'class', 'legend'

            # Resize
            resize = ->
                # Calculate dimensions
                parentHeight = $widgetBody.height()

                title = $widgetBody.children('h1')
                if (title.length)
                    $element.height(parentHeight - title.height())
                else
                    $element.height(parentHeight)

                width = $widgetBody.width()
                height = $element.height() - margin.top - margin.bottom

                # Update elements with height/width
                treemap.ratio(height / width * 0.5 * (1 + Math.sqrt(5)))

                svg.attr('width', width + margin.left + margin.right)
                    .attr('height', height + margin.bottom + margin.top)
                    .style('margin-left', -margin.left + 'px')
                    .style('margin-right', -margin.right + 'px')

                svgInner.attr 'transform', 'translate(' + margin.left + ',' + margin.top + ')'

                header.attr('y', -margin.top)
                    .attr('width', width)
                    .attr('height', margin.top)

                headerText.attr('x', 6)
                    .attr('y', 10 - margin.top)
                    .attr('dy', '.75em')

                headerIcon.attr('x', width - 20)
                    .attr('y', 10 - margin.top)
                    .attr('dy', '.75em')

                footer.attr 'width', width + margin.left + margin.right
                    .attr 'height', margin.bottom
                    .attr 'transform', 'translate(' + margin.left + ',' + (height + margin.top) + ')'
            
                # Sets x and y scale to determine size of visible boxes
                x = d3.scale.linear()
                    .domain([0, width])
                    .range([0, width])

                y = d3.scale.linear()
                    .domain([0, height])
                    .range([0, height])

                svg.classed 'monochrome', not scope.useColor

                # Generate Legend
                if scope.showLegend

                    # Shave a pixel off each side so it aligns with the inner borders of the treemap
                    adjWidth = width - 2
                    legendBoxCount = Math.floor(adjWidth / 40)
                    legendItemWidth = adjWidth / legendBoxCount

                    legendBoxes = legend.selectAll 'g'
                        .data(num for num in [0..(legendBoxCount - 1)])

                    newLegendBoxes = legendBoxes.enter()
                        .append 'g'

                    newLegendBoxes.append 'rect'
                    newLegendBoxes.append 'text'
                    
                    colorIncrements = (d) ->
                        (scope.colorDomain[scope.colorDomain.length - 1] - scope.colorDomain[0])/(legendBoxCount - 1)*d + scope.colorDomain[0]

                    legendBoxes
                        .selectAll 'rect'
                        .attr 'fill', (d) -> scope.colorScale(colorIncrements(d))
                        .attr 'x', (d) -> 1 + margin.left + d * legendItemWidth
                        .attr 'y', 0
                        .attr 'width', legendItemWidth
                        .attr 'height', margin.bottom

                    legendBoxes
                        .selectAll 'text'
                        .text (d) -> formatColorNumber(colorIncrements(d))
                        .attr 'y', Math.floor(margin.bottom * .66)
                        .attr 'x', (d) -> 1 + margin.left + d * legendItemWidth + (legendItemWidth / 2.0)
                
                else if legend?
                    legend.selectAll 'g'
                        .remove()


            initialize = (root) ->
                root.x = root.y = 0
                root.dx = width
                root.dy = height
                root.depth = 0

            # Aggregate the values for internal nodes. This is normally done by the
            # treemap layout, but not here because of our custom implementation.
            # We also take a snapshot of the original children (_children) to avoid
            # the children being overwritten when when layout is computed.
            accumulate = (d) ->
                d._children = d.children

                if d.children?
                    # recursion step, note that p and v are defined by reduce
                    fn = (p, v) -> p + accumulate(v)
                    d.value = d.children.reduce fn, 0
                else
                    v = d[scope.valueProperty]
                    v = parseFloat(v) unless _.isNumber v
                    d.value = v

            # Compute the treemap layout recursively such that each group of siblings
            # uses the same size (1×1) rather than the dimensions of the parent cell.
            # This optimizes the layout for the current zoom state. Note that a wrapper
            # object is created for the parent node for each group of siblings so that
            # the parent’s dimensions are not discarded as we recurse. Since each group
            # of sibling was laid out in 1×1, we must rescale to fit using absolute
            # coordinates. This lets us use a viewport to zoom.
            layout = (d) ->
                if d._children
                    # treemap nodes comes from the treemap set of functions as part of d3
                    treemap.nodes { _children: d._children }

                    d._children.forEach (c) ->
                        c.x = d.x + c.x * d.dx
                        c.y = d.y + c.y * d.dy
                        c.dx *= d.dx
                        c.dy *= d.dy
                        c.parent = d

                        # recursion
                        layout(c)
            
            transition = (g1, d) ->
                return if scope.transitioning or !d?
                scope.transitioning = true

                g2 = display(d)
                t1 = g1.transition().duration(750)
                t2 = g2.transition().duration(750)

                # Update the domain only after entering new elements.
                x.domain([d.x, d.x + d.dx])
                y.domain([d.y, d.y + d.dy])

                # Enable anti-aliasing during the transition.
                svgInner.style 'shape-rendering', null

                # Draw child nodes on top of parent nodes.
                svgInner.selectAll('.depth').sort (a, b) -> a.depth - b.depth

                # Fade-in entering text.
                g2.selectAll('text').style 'fill-opacity', 0

                # Transition to the new view.
                t1.selectAll('text').call(text).style 'fill-opacity', 0
                t2.selectAll('text').call(text).style 'fill-opacity', 1
                t1.selectAll('rect').call(rect)
                t2.selectAll('rect').call(rect)

                undoOpacity = if d.parent then 1 else 0
                headerIcon.transition().duration(750).attr 'opacity', undoOpacity

                # Remove the old node when the transition is finished.
                t1.remove().each 'end', ->
                    svgInner.style 'shape-rendering', 'crispEdges'
                    scope.transitioning = false

            display = (d) ->

                g1 = svgInner.insert 'g', '.grandparent'
                    .datum d
                    .attr 'class', 'depth'

                g = g1.selectAll 'g'
                    .data d._children
                    .enter()
                    .append 'g'

                g.filter (d) -> d._children
                    .classed 'children', true
                    .on 'click', _.partial(transition, g1)

                g.selectAll '.child'
                    .data (d) -> d._children || [d]
                    .enter()
                    .append 'rect'
                    .attr 'class', 'child'
                    .call rect

                g.append 'rect'
                    .attr 'class', 'parent'
                    .call rect
                    .append 'title'
                    .text (d) -> 
                        if scope.useColor
                            d[scope.labelProperty] + ', ' + scope.valueDescription + ': ' + formatValueNumber(d.value) + ', ' + scope.colorDescription + ': ' + formatColorNumber(d[scope.colorProperty])
                        else 
                            d[scope.labelProperty] + ', ' + scope.valueDescription + ': ' + formatValueNumber(d.value)

                g.append 'clipPath'
                    .attr 'id', (d) -> 'clip-path-' + _.slugify d[scope.labelProperty]
                    .append 'rect'
                    .call rect, 2

                g.append 'text'
                    .attr 'dy', '.75em'
                    .text (d) -> d[scope.labelProperty]
                    .attr 'clip-path', (d) -> 'url(#clip-path-' + _.slugify(d[scope.labelProperty])
                    .call text

                # Bind header click event and update text
                grandparent
                    .datum d.parent
                    .on 'click', _.partial(transition, g1)
                    .select 'text'
                    .text name(d)
                    .attr 'fill', -> 
                        if scope.useColor
                            getContrast50(scope.colorScale(d[scope.colorProperty]))
                        else
                            '#333333'

                # Color header based on grandparent's colorProperty
                grandparent
                    .datum(d.parent)
                    .select 'rect'
                    .attr 'fill', -> 
                        if scope.useColor
                            scope.colorScale(d[scope.colorProperty])
                        else 
                            '#bbbbbb'

                return g

            text = (text) ->
                text.attr 'x', (d) -> x(d.x) + 6
                    .attr 'y', (d) -> y(d.y) + 6
                    .attr 'fill', (d) -> 
                        if scope.useColor
                            getContrast50(scope.colorScale(parseFloat(d[scope.colorProperty])))
                        else 
                            '#333333'

            rect = (rect, heightWidthOffset = 0) ->
                rect.attr 'x', (d) -> x(d.x)
                    .attr 'y', (d) -> y(d.y)
                    .attr 'width', (d) -> x(d.x + d.dx) - x(d.x) - heightWidthOffset
                    .attr 'height', (d) -> y(d.y + d.dy) - y(d.y) - heightWidthOffset
                
                if scope.useColor
                    rect.attr 'fill', (d) -> scope.colorScale(parseFloat(d[scope.colorProperty]))
                else 
                    rect.attr 'fill', null

            name = (d) ->
                if d.parent
                    name(d.parent) + ', ' + d[scope.labelProperty]
                else
                    d[scope.labelProperty]

            scope.$watch 'data', (root) ->
                return unless root?

                initializeColors();
                resize()

                initialize(root)
                accumulate(root)
                layout(root)

                # Remove last displayed element so it can be redrawn without duplicating
                d3.select(_.last(svgInner.selectAll('.depth')[0])).remove()

                display(root)

            # Update on window resizing
            $widgetBody.on 'resize', _.debounce ->
                # Recalculate dimensions
                resize()
                initialize(scope.data)
                layout(scope.data)

                # Remove last displayed element so it can be redrawn without duplicating
                d3.select(_.last(svgInner.selectAll('.depth')[0])).remove()

                # Redraw
                display(scope.data)
            , 100, { leading: false, maxWait: 300 }

            #
            # Cleanup
            #
            scope.$on '$destroy', ->
                $widgetBody.off 'resize'
                return

            return
    }
