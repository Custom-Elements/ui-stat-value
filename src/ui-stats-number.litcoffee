# ui-stats-number
The Number tile is focused on the display of a metric that can be represented by a single number,
along with associated secondary metrics, such as a change indicator or sparkline.

    numeral = require 'numeral'
    _ = require 'lodash'
    Promise = require 'bluebird'
    request = Promise.promisifyAll require 'request'

    Polymer 'ui-stats-number',
    
## Attributes and Change Handlers

### units
Text prefix prepended to the value, for example "$" or "ms"

### value
The primary metric and should be a number. The primary number is formatted according to the usual formatting rules.

      valueChanged: (oldValue, newValue) ->
        @values = [ @value ]

### values
An array of previous values, used to create a sparkline if present

      valuesChanged: (oldValue, newValue) ->
        
Values is trunctated to the last `maxValues` elements of the array

        data = @values.slice -@maxValues
        
The primary value is the result of applying the reduction `function`, unless overriden. By default we sum the values
if we have more than 2 values, otherwise we show the last value

        if not @function?
          @function = "sum" if data.length > 2
          @function = "last" if data.length <= 2
          console.log "Function is #{@function}"
        @primaryMetric = @applyReduction @function, data
          
        console.log "#{@name}, #{data}"
        switch data.length
          when 1
            @change = null
          when 2
            @change = (data[1] - data[0]) / data[0] unless @absolute
            @change = data[1] - data[0] if @absolute
          else
            @change = null
            chartValues = _.map data, (value) -> ["x", value]
            chartValues.unshift ["x", "y"]
            @$.trend.setAttribute 'data', JSON.stringify chartValues
            @lastValue = _.last data

        console.log "#{@name}: smoothing is #{@smooth}, #{@sparklineOptions.curveType}"

Reduction function, specified by the `@function` attribute

      applyReduction: (operation, values) ->
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

### src
A url that returns an array of JSON objects and will be used to populate the sparkline

      srcChanged: (oldValue, newValue) ->
        @loading = true
        request.getAsync(@src)
          .spread (res, body) =>
            json = JSON.parse body
            @values = _.pluck json, @property
            @loading = false
          .catch (err) ->
            console.log err

### smooth

      smoothChanged: (oldValue, newValue) ->
        @sparklineOptions.curveType = if @smooth? then "function" else "none"
        @$.trend.setAttribute 'options', JSON.stringify @sparklineOptions

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
        @values =  []
        @data = []
        @units = ""
        @value = null
        @change = null
        @primaryMetric = null
        @function = null
        @maxValues = 100
        @absolute = false
        @smooth = false

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
          colors: [ 'white' ]
          curveType: if @smooth? then 'none' else 'function'


      ready: ->

      attached: ->

      domReady: ->
        @$.trend.setAttribute 'options', JSON.stringify @sparklineOptions

      detached: ->
