# ui-stats-chart
The Chart tile displays a chart in various formats

    _ = require 'lodash'
    Promise = require 'bluebird'
    request = Promise.promisifyAll require 'request'

    Polymer 'ui-stats-chart',

## Attributes and Change Handlers

      observe:
          properties: 'draw'
          values: 'draw'

### values
An array of previous values, used to create a sparkline if present

      propertyChanged: (oldValue, newValue) ->
        @properties = [ @property ]

### type
        
      typeChanged: (oldValue, newValue) ->
        @chartOptions.legend = if @type is "pie" then "" else "none"
        @$.chart.setAttribute 'options', JSON.stringify @chartOptions

## Methods

      draw: ->
        return if not @properties? and @values?
        
        @properties.unshift "" if @properties.length < 2
        data = @values.slice -@maxValues
        chartValues = _.map data, (item) =>
          if typeIsArray item
            item
          else if typeof item is "object"
            [ item[@properties[0]], item[@properties[1]] ]
          else if typeof item is "number"
            [item[@properties[0]], item]

        chartValues.unshift @properties
        console.log "ChartValues for #{@name}", chartValues
        @$.chart.setAttribute 'data', JSON.stringify chartValues
        console.log "Data for #{@name}", data        

## Polymer Lifecycle

      created: ->
        @values = []
        @properties = ["x", "y"]
        @property = ""
        @type = 'line'
        @maxValues = 100
        @chartOptions =
        chartArea:
          width: '85%'
          height: 'auto'
        legend: 'none'

      domReady: ->
        @$.chart.setAttribute 'options', JSON.stringify @chartOptions



## Helpers
    
    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
