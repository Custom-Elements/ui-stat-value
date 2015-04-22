# ui-stats-chart
The Chart tile displays a chart in various formats

    _ = require 'lodash'
    Promise = require 'bluebird'
    request = Promise.promisifyAll require 'request'
    moment = require 'moment'

    Polymer 'ui-stats-chart',

## Attributes and Change Handlers

      observe:
          cols: 'draw'
          data: 'draw'

      propertyChanged: (oldValue, newValue) ->
        @cols = [ @property ]

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
        

## Methods

      draw: ->
        return if not @cols? and @data?

        @$.chart.cols = _.map @cols, (col) ->
          col.label = col.id unless col.label?
          col
        console.log "cols for #{@name}", @$.chart.cols

        @$.chart.rows = _.map @data.slice(-@limit), (item) =>
          if typeIsArray item
            item
          else if typeof item is "object"
            x = @getValue item, @cols[0]
            y = @getValue item, @cols[1]
            [ x, y ]
          else if typeof item is "number"
            x = item[@cols[0]
            y = item
            [ x, y ]
        console.log "rows for #{@name}", @$.chart.rows
        
      getValue: (item, col) ->
        value = item[[col.id]]
        switch col.type
          when 'date'
            col.pattern = 'YYYY-MM-DD' unless col.pattern?
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
        @cols = [{label:'x', type:'string'}, {label:'y', type:'number'}]
        @property = ""
        @type = 'line'
        @limit = 100
        @loading = false

        @chartOptions =
        chartArea:
          width: '85%'
          height: 'auto'
        legend: 'none'

      domReady: ->
        @$.chart.options = @chartOptions



## Helpers
    
    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

    isNumeric = (n) -> not isNaN(parseFloat(n)) && isFinite(n)
