# ui-stats-number
The Number tile is focused on the display of a metric that can be represented by a single number,
along with associated secondary metrics, such as a change indicator or sparkline.

    _ = require 'lodash'
    numeral = require 'numeral'
    RequestCache = require './request.litcoffee'

    Polymer 'ui-stats-number',
    
## Attributes and Change Handlers

      valueChanged: ->
        @data = [ @value ]

deprecated properties

      functionChanged: ->
        @reduction = @function


      dataChanged: ->
        
Data is trunctated to the last `limit` elements of the array

        data = @data.slice -@limit
        
The primary value is the result of applying the reduction `function`, unless overriden. By default we sum the values
if we have more than 2 values, otherwise we show the last value

        if not @reduction?
          @reduction = "sum" if data.length > 2
          @reduction = "last" if data.length <= 2
        @primaryMetric = @reduce @reduction, data
          
        #console.log "NumberStat: #{@name}, #{data}"
        switch data.length
          when 1
            @change = null
          when 2
            @change = (data[1] - data[0]) / data[0] unless @absolute
            @change = data[1] - data[0] if @absolute is true
          else
            @change = null
            chartValues = _.map data, (value) -> ["x", value]
            chartValues.unshift ["x", "y"]
            @$.trend.data = chartValues
            @lastValue = _.last data

      srcChanged: ->
        @loading = true
        request = window.ui_stats_cache ?= new RequestCache()
        request.loadDataForUrlAsync @src, @method, (err, json) =>
          @loading = false
          if err
            console.error "Error loading data from #{@src}", err
          else
            @data = _.pluck json, @property

      smoothChanged: ->
        @sparklineOptions.curveType = if @smooth is true then "function" else "none"
        @$.trend.options = @sparklineOptions

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

## Helpers

Reduction function, specified by the `@reduction` attribute

      reduce: (operation, values) ->
        switch operation
          when "first" then return _.first values
          when "last" then return _.last values
          when "min" then return _.min values
          when "max"then return _.max values
          when "count"then return values.length
          when "sum"
            return _.reduce values, (sum, value) ->
              sum + value
            ,0
          when "average"
            sum = _.reduce values, (sum, value) ->
              sum + value
            ,0
            return sum / values.length       
          else return _.last values

## Event Handlers

      onGoogleChartRender: ->
        @sparkline = true

## Polymer Lifecycle

      created: ->
        @data =  []
        @units = ""
        @value = null
        @change = null
        @primaryMetric = null
        @reduction = null
        @limit = 100
        @absolute = false
        @smooth = false
        @method = 'GET'

        @sparklineOptions =
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
          colors: [ 'blue' ]

      domReady: ->
        @$.trend.options = @sparklineOptions
