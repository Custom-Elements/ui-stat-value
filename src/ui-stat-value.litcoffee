# ui-stat-value
The Value visualisation is focused on the display of a metric that can be represented by a single number,
along with associated secondary metrics, such as a change indicator or sparkline.

    numeral = require 'numeral'
    _ = require 'lodash'
    $ = require 'jquery'

Define a set of chart options for our sparkline

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
      colors: [ 'white' ]

    Polymer 'ui-stat-value',

## Attributes and Change Handlers

### units
Text prefix prepended to the value, for example "$" or "ms"

### value
The primary metric and should be a number. The primary number is formatted according to the usual formatting rules.

      valueChanged: (oldValue, newValue) ->
        @update()

### previous
The previous value of the metric, this should be a number. If specified, a previous value shows the comparision value.

      previousChanged: (oldValue, newValue) ->
        @update()

### values
An array of previous values, used to create a sparkline if present

      valuesChanged: (oldValue, newValue) ->
        @$.trend.setAttribute 'options', JSON.stringify sparkline
        data = _.map @values, (value) -> ["x", value]
        data.unshift ["x", "y"]
        @$.trend.setAttribute 'data', JSON.stringify data
        
        @value = _.last @values if not @value?

### url
A url that returns an array of JSON objects and will be used to populate the sparkline

      # todo: replace with request.js, don't load jquery
      urlChanged: (oldValue, newValue) ->
        @loading = true
        $.ajax
          type: 'POST'
          url: 'https://query.glgroup.com/councilApplicant/getStats.mustache'
          contentType: 'application/json'
          dataType: 'jsonp'
          success: (json) =>
            @values = _.pluck(json, @property).slice(-@maxValues)
            # really could wait till we get the graph drawn event
            @loading = false

## maxValues
The maximum number of values to consider when drawing the sparkline

## label
Title of the primary metric

## Computed Properties

## Methods

      update: ->
        if @previous
          @change = (@value - @previous) / @previous
        else
          @change = null

## Filters

Pretty formatting of numbers

      decimalNumber: (value) ->
        numeral(value).format '0,0[.]00'
      
      percentage: (value) ->
        numeral(value).format '0.0%'

Splits numbers into whole and fractional parts so we can style them separately
        
      wholenumber: (string) ->
        _.first string.split '.'
      
      fraction: (string) ->
        ".#{_.last string.split '.'}" if string.match /\./

## Event Handlers

## Polymer Lifecycle

      created: ->
        @units = ""
        @value = null
        @previous = null
        @change = null
        @values = []
        @maxValues = 30
        @loading = @url?

      ready: ->

      attached: ->

      domReady: ->

      detached: ->
