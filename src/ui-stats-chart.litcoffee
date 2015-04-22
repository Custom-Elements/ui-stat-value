# ui-stats-chart
The Chart tile displays a chart in various formats

    _ = require 'lodash'
    Promise = require 'bluebird'
    request = Promise.promisifyAll require 'request'
    moment = require 'moment'

    Polymer 'ui-stats-chart',

## Attributes and Change Handlers

      observe:
          data: 'draw'

### type
        
      typeChanged: (oldValue, newValue) ->
        @chartOptions.legend = if @type is "pie" then "" else "none"
        @$.chart.setAttribute 'options', JSON.stringify @chartOptions
        
      srcChanged: (oldValue, newValue) ->
        @loading = true
        request.getAsync(@src)
          .spread (res, body) =>
            @data = JSON.parse body
            @loading = false
          .catch (err) ->
            console.log err
      
      colsChanged: (oldValue, newValue) ->
        @$.chart.cols = _.map @cols, (col) ->
          col.label = col.id unless col.label?
          col
        console.log "cols for #{@name}", @$.chart.cols

## Methods

      draw: ->
        return if not @cols? and @data?
        console.log "Drawing #{@name}"
        @$.chart.rows = _.map @data.slice(-@limit), (item) =>
          if typeIsArray item
            x = @getValue item[0], @cols[0]
            y = @getValue item[1], @cols[1]
            [ x, y ]
          else if typeof item is "object"
            x = @getValue item, @cols[0]
            y = @getValue item, @cols[1]
            [ x, y ]
          else if typeof item is "number"
            x = ""
            y = item
            [ x, y ]
        console.log "rows for #{@name}", @$.chart.rows
        
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
            width: '85%'
            height: 'auto'
          legend: 'none'
        @cols = [{label:'', type:'string'}, {label:'', type:'number'}]

      domReady: ->
        @$.chart.options = @chartOptions
        @$.chart.cols = @cols



## Helpers
    
    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

    isNumeric = (n) -> not isNaN(parseFloat(n)) && isFinite(n)
