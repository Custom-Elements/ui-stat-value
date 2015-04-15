# ui-stat-value
The Value visualisation is focused on the display of a metric that can be represented by a single number,
along with associated secondary metrics, such as a change or trend indication.

    numeral = require 'numeral'
    _ = require 'lodash'

    sparkline =
      chartArea:
        width: '100%'
        height: '100%'
      hAxis:
        textPosition: 'none'
        gridlines:
          color: 'transparent'
        viewWindowMode: 'maximized'
      vAxis:
        textPosition: 'none'
        gridlines:
          color: 'transparent'
        viewWindowMode: 'maximized'
      baselineColor: 'transparent'
      enableInteractivity: false
      legend: 'none'
      backgroundColor: 'transparent'

    Polymer 'ui-stat-value',

## Attributes and Change Handlers

### units
Text prefix prepended to the value, for example "$" or "ms"

### value
The primary metric and should be a number. The primary number is formatted according to the usual formatting rules.

      valueChanged: (oldValue, newValue) ->
        @update()

## previous
The previous value of the metric, this should be a number. If specified, a previous value shows the comparision value.

      previousChanged: (oldValue, newValue) ->
        @update()

## values
An array of previous values, used to create a trend graph

      valuesChanged: (oldValue, newValue) ->
        @$.trend.setAttribute 'options', JSON.stringify sparkline
        data = _.map @values, (value) -> ["x", value]
        data.unshift ["X", "Y"]
        @$.trend.setAttribute 'data', JSON.stringify data

## Computed Properties

## Methods

      update: ->
        if @previous
          @change = (@value - @previous) / @previous
        else
          @change = null

## Filters

      decimalNumber: (value) ->
        numeral(value).format '0,0[.]00'
      
      percentage: (value) ->
        numeral(value).format '0[.]00%'

## Event Handlers

## Polymer Lifecycle

      created: ->
        @units = ""
        @value = 0
        @previous = null
        @change = null
        @values = []

      ready: ->

      attached: ->

      domReady: ->

      detached: ->
