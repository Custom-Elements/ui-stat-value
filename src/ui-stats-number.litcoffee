# ui-stats-number
The Number tile is focused on the display of a metric that can be represented by a single number,
along with associated secondary metrics, such as a change indicator or sparkline.

    numeral = require 'numeral'
    _ = require 'lodash'
    $ = require 'jquery'

    Polymer 'ui-stats-number',

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
        sparklineOptions =
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
          curveType: if @smooth? then "function" else "none"
        
        dataValues = @values.slice(-@maxValues)
        if @values.length > 1
          @$.trend.setAttribute 'options', JSON.stringify sparklineOptions
          data = _.map dataValues, (value) -> ["x", value]
          data.unshift ["x", "y"]
          @$.trend.setAttribute 'data', JSON.stringify data
          @lastValue = _.last dataValues

Apply functional reduction, if any.

          if not @value
            switch @function
              when "first"
                @value = _.first dataValues
              when "last"
                @value = _.last dataValues
              when "min"
                @value = _.min dataValues
              when "max"
                @value = _.max dataValues
              when "count"
                @value = dataValues.length
              when "sum"
                @value = _.reduce dataValues, (sum, value) ->
                  sum + value
                ,0
              when "average"
                sum = _.reduce dataValues, (sum, value) ->
                  sum + value
                ,0
                @value = sum / dataValues.length
              
              else @value = _.last dataValues

### src
A url that returns an array of JSON objects and will be used to populate the sparkline

      # todo: replace with request.js, don't load jquery
      srcChanged: (oldValue, newValue) ->
        @loading = true
        $.ajax
          type: 'POST'
          url: @src
          contentType: 'application/json'
          dataType: 'jsonp'
          success: (json) =>
            @values = _.pluck json, @property
            @loading = false

## maxValues
The maximum number of values to consider when drawing the sparkline

## name
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

      onGoogleChartRender: ->
        @sparkline = true

## Polymer Lifecycle

      created: ->
        @units = ""
        @value = null
        @previous = null
        @change = null
        @values = []
        @function = "sum"
        

      ready: ->

      attached: ->

      domReady: ->

      detached: ->
