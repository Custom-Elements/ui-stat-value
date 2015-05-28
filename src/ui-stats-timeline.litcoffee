    _ = require 'lodash'
    moment = require 'moment'
    numeral = require 'numeral'
    RequestCache = require './request.litcoffee'

    Polymer 'ui-stats-timeline',
    
      created: ->
        @label = "Timeline"
        @datePattern = "YYYY-MM-DD"
        @data = []
        @loading = false
        @dateProperty = 'date'
        @valueProperty = 'value'
        @valueProperties = [ 'value' ]
        @reduction = 'average'
        @groupBy = 'day'
        @groupByFunction = 'sum'
        @units = ''
        @limit = Number.MAX_VALUE
        @value = ''
        @smooth = true
        @type = 'line'
        @trendline = false
        @method = 'GET'
        @transformFunction = 'none'        

      domReady: ->
        @$.chart.options =
          fontSize: 8
          legend:
            position: 'none'
            color: '#aaa'
            alignment: 'center'
            textStyle:
              color: '#aaa'
              fontSize: 9
          series: [ color: 'black' ]
          lineWidth: 2
          pointSize: 0
          chartArea:
            left: 50
            top: 15
            width: "100%"
          vAxis:
            format: "#,####{@units}"
            textStyle:
              color: '#aaa'
            baselineColor: '#aaa'
          hAxis:
            textStyle:
              color: '#aaa'
            baselineColor: '#aaa'
      valuePropertyChanged: ->
        @valueProperties = [ @valueProperty ]

property handlers
        
      srcChanged: ->
        @loading = true
        request = window.ui_stats_cache ?= new RequestCache()
        request.loadDataForUrlAsync @src, @method, (err, json) =>
          @loading = false
          if err
            console.log "Error loading data from #{@src}", err
          else
            @data = json

      transformChanged: ->
        matches = /^(\w+)\((.*?)\)?$/.exec @transform
        if matches
          @transformFunction = matches[1]
          @transformArgs = if matches[2]? then parseInt(matches[2]) else 0
        else
          @transformFunction = @transform
          @transformArgs = 0

deprecated properties

      functionChanged: ->
        @reduction = @function

other stuff
      
      createDataFromJson: (json) ->
        values = _.map json, (item) =>
          dateObject = moment(item[@dateProperty], @datePattern).toDate()
          values = [ dateObject ]
          for property in @valueProperties
            values.push parseFloat item[property]
          values

sort by date ascending

        sortedValues = _.sortBy values, (a, b) ->
          dateA = moment a[0]
          dateB = moment b[0]
          dateA.diff(dateB)

        @applyGrouping sortedValues
          
      applyGrouping: (arrayOfArrays) ->
        return arrayOfArrays if not @groupBy?
        grouped = _.groupBy arrayOfArrays, (array) =>
          moment(array[0]).startOf(@groupBy).format(@datePattern)
        _.map grouped, (items, date) =>
          dateObject = moment(date, @datePattern).toDate()
          result = [ dateObject ]
          for propertyName, index in @valueProperties
            values = _.map items, (array) -> parseFloat array[index + 1]
            value = @applyReductionFunction @groupByFunction, values
            result.push parseFloat(value.toFixed(2))
          result

      calculateValue: (rows) ->
        seriesValues = []
        for propertyName, index in @valueProperties
          values = _.map rows, (row) -> row[index + 1]
          seriesValues.push @applyReductionFunction @reduction, values
        value = @applyReductionFunction @reduction, seriesValues
        @value = switch @units
          when '%'
            numeral(value * 100).format '0.0'
          else
            numeral(value).format '0,0[.]00'

      applyReductionFunction: (f, data) ->
        return 0 if not data.length?
        value = switch f
          when 'average'
            _.sum(data) / data.length
          when 'sum'
            _.sum data
          when 'min'
            _.min data
          when 'max'
            _.max data
          when 'first'
            _.first data
          when 'last'
            _.last data
          when 'count'
            data.length
          when 'cumulative'
            @accumulate data
          when 'none'
            0
          else
            _.sum data

      applyTransform: (rows) ->
        return rows if @transformFunction is 'none'
        transformed = {}
        for propertyName, propertyIndex in @valueProperties
          values = _.map rows, (row) -> row[propertyIndex + 1]
          if @transformFunction in ['weightedMovingAverage', 'movingAverage']
            transformed[propertyName] = @movingAverage values, @transformArgs
          else if @transformFunction is 'cumulative'
            transformed[propertyName] = @accumulate values
          else
            transformed[propertyName] = values
        rowIndex = 0
        _.map rows, (row) =>
          result = [ row[0] ]
          for propertyName in @valueProperties
            result.push transformed[propertyName][rowIndex]
          rowIndex++
          result
      
      accumulate: (values) ->
        results = []
        for value,index in values
          results.push _.sum values.slice(0,index)
        results
        
      movingAverage: (values, lookback) ->
        lookback = if lookback > 0 then lookback else 7
        results = []
        window = []
        for value in values
          window.push value
          window.shift() if window.length > lookback

          if @transformFunction is 'weightedMovingAverage'
            index = 0
            results.push _.reduce window, (total, n) ->
              index++
              multiplier = index / _.sum [1..window.length]
              total + n * multiplier
            , 0
          else
            results.push _.sum(window) / window.length
        results

      dataChanged: ->
        rows = @applyTransform(@createDataFromJson(@data)).slice -@limit
        
        @calculateValue(rows)
        console.log "Timeline #{@label}",rows

        columns = [ { "label": "Date", "type": "date" } ]
        for property in @valueProperties
          columns.push { "label": property, "type": "number" }
        @$.chart.cols = columns

        @$.chart.options.curveType = if @smooth is true then "function" else "none"
        @$.chart.options.trendlines = { 0: {} } if @trendline

        @$.chart.type = @type
        if @$.chart.cols.length > 2
          @$.chart.options.legend.position = 'top'
          @$.chart.options.chartArea.top += 10
          @$.chart.options.series = []

        @$.chart.rows = rows
