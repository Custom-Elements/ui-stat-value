# ui-stats-chart
The Chart tile displays a chart in various formats

    _ = require 'lodash'
    Promise = require 'bluebird'
    request = Promise.promisifyAll require 'request'
    moment = require 'moment'

    Polymer 'ui-stats-chart',

## Attributes and Change Handlers

      srcChanged: ->
        @loading = true
        request.getAsync(@src)
          .spread (res, body) =>
            @data = JSON.parse body
            @loading = false
          .catch (err) ->
            console.log err
      
      dataChanged: ->
      
Normalize columns, adding default labels, etc

        cols = _.map @cols, (col) ->
          col.label = col.label ? col.id 
          col.type = col.type ? "number"
          col.pattern = col.pattern ? 'YYYY-MM-DD'
          col

Special case for single column data

        if cols.length is 1
          cols = [{label:'', type:'string'}, cols[0]]
        @$.chart.cols = cols
        console.log "cols for #{@name}", @$.chart.cols

Customize chart options based on the type of data we are showing, and other settings

        @$.chart.options.curveType = if @smooth? then "function" else "none"

        if @type is 'pie'
          @$.chart.options.legend = { position: 'right' }
        else if cols.length > 2
          @$.chart.options.legend = { position: 'top', alignment: 'center' }
        else
          @$.chart.options.legend = { position: 'none' }
          
        if cols[0].type is 'date'
          @$.chart.options.hAxis = { format: 'M/d' }
        else if @type isnt 'pie'
          @$.chart.options.hAxis = { }
        
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
            return moment(value, col.pattern).toDate()
          when 'string'
            return value.toString()
          when 'number'
            return parseFloat value
          else
            return value

## Polymer Lifecycle

      created: ->
        @data = []
        @type = 'line'
        @limit = 1000
        @loading = false
        @initialized = false

        @cols = [{label:'', type:'string'}, {label:'', type:'number'}]

      domReady: ->
        @initialized = true

## Helpers
    
    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

    isNumeric = (n) -> not isNaN(parseFloat(n)) && isFinite(n)
