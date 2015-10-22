# ui-stats-chart
The Chart tile displays a chart in various formats

    _ = require 'lodash'
    moment = require 'moment'
    RequestCache = require './request.litcoffee'

    Polymer 'ui-stats-chart',

## Attributes and Change Handlers

      onLoadChanged: ->
        @onLoadHandler = eval @onLoad

      widthChanged: ->
        @$.chart.style.width = @width

      srcChanged: ->
        @loading = true
        request = window.ui_stats_cache ?= new RequestCache()
        request.loadDataForUrlAsync @src, @method, (err, json) =>
          @loading = false
          if err
            console.error "Error loading data from #{@src}", err
          else
            @data = @onLoadHandler JSON.parse JSON.stringify(json)

      dataChanged: ->
        @values = @data
        if @groupBy in ['week', 'month', 'day']
          # find the first date column
          dateColumn = _.find @cols, (col) ->
            col.type is 'date'
          # group value by the date column
          pattern = dateColumn.pattern ? 'YYYY-MM-DD'
          grouped = _.groupBy @values, (item) =>
            m = moment(item[dateColumn.id], pattern)
            m.startOf(@groupBy).format(pattern)
          # sum each property in the data, by week
          @values = _.map grouped, (items, date) ->
            o = {}
            o[dateColumn.id] = moment(date, pattern).toDate()
            for item in items
              for key, value of item
                continue if key is dateColumn.id
                o[key] = 0 if not o[key]?
                o[key] += value
            o

        @redraw()

      redraw: ->

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

Customize chart options based on the type of data we are showing, and other settings

        @$.chart.options.curveType = if @smooth is true then "function" else "none"

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

        @$.chart.rows = _.map @values.slice(-@limit), (item) =>
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
        #console.log "Charting #{@name}: ", @$.chart.rows

Parse values to the correct type

      getValue: (item, col) ->
        if typeof item is "object"
          value = item[[col.id]]
        else
          value = item
        switch col.type
          when 'date'
            return value if value instanceof Date
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
        @values = []
        @type = 'line'
        @limit = 1000
        @loading = false
        @initialized = false
        @groupBy = ''
        @method = 'GET'
        @onLoadHandler = (json) -> json

        @cols = [{label:'', type:'string'}, {label:'', type:'number'}]

      domReady: ->
        @initialized = true

## Helpers

    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

    isNumeric = (n) -> not isNaN(parseFloat(n)) && isFinite(n)
