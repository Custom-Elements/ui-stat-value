# ui-stats-chart
The Chart tile displays a chart in various formats

    _ = require 'lodash'
    Promise = require 'bluebird'
    request = Promise.promisifyAll require 'request'
    moment = require 'moment'

    Polymer 'ui-stats-chart',

## Attributes and Change Handlers

      typeChanged: (oldValue, newValue) ->
        @chartOptions.legend = if @type is "pie" then "" else "none"
        @$.chart.options = @chartOptions

      smoothChanged: (oldValue, newValue) ->
        @chartOptions.curveType = if @smooth? then "function" else "none"
        @$.chart.options = @chartOptions

      srcChanged: (oldValue, newValue) ->
        @loading = true
        request.getAsync(@src)
          .spread (res, body) =>
            @data = JSON.parse body
            @loading = false
          .catch (err) ->
            console.log err
      
      dataChanged: (oldValue, newValue) ->

Normalize columns, adding default labels, etc

        cols = _.map @cols, (col) ->
          col.label = col.label ? col.id 
          col.type = col.type ? "number"
          col
        if cols.length is 1
          cols = [{label:'', type:'string'}, cols[0]]
        console.log "cols for #{@name}", cols
        @$.chart.cols = cols
        
        # if cols.length > 2
        #   @chartOptions.legend = { position: 'bottom' }
        #   @$.chart.options = @chartOptions

Prepare the row data

        @$.chart.rows = _.map @data.slice(-@limit), (item) =>
          if typeIsArray item
            x = @getValue item[0], cols[0]
            y = @getValue item[1], cols[1]
            [ x, y ]
          else if typeof item is "object"
            if @cols.length is 1
              [ "", @getValue item, cols[1] ]
            else
              _.map cols, (col) =>
                @getValue item, col
          else if typeof item is "number"
            [ "", item ]
        console.log "Charting #{@name}: ", @$.chart.rows

Parse values to the correct type

      getValue: (item, col) ->
        if typeof item is "object"
          value = item[[col.id]]
        else
          value = item
        switch col.type
          when 'date'
            col.pattern = col.pattern ? 'YYYY-MM-DD'
            return moment(value, 'YYYY-MM-DD').toDate()
          when 'string'
            return value.toString()
          when 'number'
            return parseFloat value
          else
            return value

## Polymer Lifecycle

      created: ->
        @data = []
        @property = ""
        @type = 'line'
        @limit = 100
        @loading = false

        @chartOptions =
          chartArea:
            width: 'auto'
            height: 'auto'
          legend: 'none'
        @cols = [{label:'', type:'string'}, {label:'', type:'number'}]

      domReady: ->
        @$.chart.options = @chartOptions

## Helpers
    
    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

    isNumeric = (n) -> not isNaN(parseFloat(n)) && isFinite(n)
