    _ = require 'lodash'
    moment = require 'moment'
    numeral = require 'numeral'
    RequestCache = require './request.litcoffee'
    lsq = require 'least-squares'

    Polymer 'ui-stats-timeline',
    
      created: ->
        @label = "Timeline"
        @datePattern = "YYYY-MM-DD"
        @data = []
        @loading = false
        @dateProperty = 'date'
        @valueProperty = ''
        @valueProperties = [ ]
        @reduction = 'last'
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
        @change = 0
        @totalChange = 0
        @absoluteChange = false
        @invertChange = false
        @showChange = true
        @since = null
        @until = null
        @includePartialGroups = false
        @onLoadHandler = (json) -> json
        @isStacked = false

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
            @data = @onLoadHandler JSON.parse JSON.stringify(json)

      transformChanged: ->
        matches = /^(\w+)\((.*?)\)?$/.exec @transform
        if matches
          @transformFunction = matches[1]
          @transformArgs = if matches[2]? then parseInt(matches[2]) else 0
        else
          @transformFunction = @transform
          @transformArgs = 0
          
      onLoadChanged: ->
        @onLoadHandler = eval @onLoad

deprecated properties

      functionChanged: ->
        @reduction = @function

other stuff
      
      createDataFromJson: (json) ->
        values = _.map json, (item) =>
          dateObject = moment(item[@dateProperty], @datePattern).toDate()
          values = [ dateObject ]
          
          if @valueProperties.length is 0
            for key of item
              @valueProperties.push key if key isnt @dateProperty
          
          for property in @valueProperties
            values.push parseFloat item[property]
          values

sort by date ascending, in case they come in out of order

        sortedValues = _.sortBy values, (a, b) ->
          momentA = moment a[0]
          momentB = moment b[0]
          momentA.diff momentB

filter data by date ranges

        if @since? or @until?
          sinceMoment = if @since? then moment @since, @datePattern else moment '1970-01-01'
          sinceMoment = sinceMoment.subtract(1, 'days').endOf('day')
          untilMoment = if @until? then moment @until, @datePattern else moment '2112-12-31'
          untilMoment = untilMoment.add(1, 'days').startOf('day')
          sortedValues = _.filter sortedValues, (array) ->
            itemMoment = moment(array[0])
            itemMoment.isBetween sinceMoment, untilMoment

        @applyGrouping sortedValues
          
Group by date bucket

      applyGrouping: (arrayOfArrays) ->
        return arrayOfArrays if not @groupBy?
        
group by time period
        
        grouped = _.groupBy arrayOfArrays, (array) =>
          moment(array[0]).startOf(@groupBy).format(@datePattern)
        now = moment()
        _.compact _.map grouped, (items, date) =>
          m =  moment(date, @datePattern)

throw out the outliers to prevent the most recent group from under reporting

          if not @includePartialGroups
            if m.isSame now, @groupBy
              return null      

          dateObject = m.toDate()
          result = [ dateObject ]
          for propertyName, index in @valueProperties
            values = _.map items, (array) -> parseFloat array[index + 1]
            value = @applyReductionFunction @groupByFunction, values
            result.push value
          result
          
      calculateTrendLine: (rows) =>
        # todo deal with multiple series? just uses first for now, maybe trend=2
        series = 1
        offset = _.first(rows)[0].getTime()
        xValues = _.map rows, (array) -> array[0].getTime() - offset
        yValues = _.map rows, (array) -> array[series]
        trendFunction = lsq(xValues, yValues)
        _.each rows, (array, index) ->
          array.push trendFunction(xValues[index])

      calculateValue: (rows) ->
        # use trendline if present
        seriesValues = []
        for propertyName, index in @valueProperties
          values = _.map rows, (row) -> row[index + 1]
          seriesValues.push @applyReductionFunction @reduction, values
        @value = @applyReductionFunction @reduction, seriesValues
            
      calculateChange: (rows) ->
        # use trendline if present
        if rows.length < 2 or @valueProperties.length > 1
          return @change = 0
        initialValue = _.first(rows)[1]
        currentValue = _.last(rows)[1]
        previousValue = rows[rows.length - 2][1]
        delta = currentValue - previousValue
        totalDelta = currentValue - initialValue
        if @absoluteChange
          @change = delta
          @totalChange = totalDelta
        else
          if previousValue is 0
            @change = 0
          else
            @change = delta / previousValue
          if initialValue is 0
            @totalChange = 0
          else
            @totalChange = totalDelta / initialValue
        @improving = @change < 0 and @invertChange or @change > 0 and !@invertChange
        @totalImproving = @totalChange < 0 and @invertChange or @totalChange > 0 and !@invertChange
        
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
          when 'none'
            0
          else
            _.sum data

      applyTransform: (rows) ->
        return rows if @transformFunction is 'none'
        
        if @transformFunction in [ 'movingAverage', 'weightedMovingAverage', 'cumulative']
          transformFunction = eval "this.transform_#{@transformFunction}"
        else
          transformFunction = eval @transformFunction

        transformed = {}
        for propertyName, propertyIndex in @valueProperties
          values = _.map rows, (row) -> row[propertyIndex + 1]
          transformed[propertyName] = transformFunction values, @transformArgs
        rowIndex = 0
        _.map rows, (row) =>
          result = [ row[0] ]
          for propertyName in @valueProperties
            result.push transformed[propertyName][rowIndex]
          rowIndex++
          result
      
      transform_cumulative: (values) ->
        results = []
        for value,index in values
          results.push _.sum values.slice(0,index)
        results

      transform_weightedMovingAverage: (values, lookback) ->
        lookback = if lookback > 0 then lookback else 7
        results = []
        window = []
        for value in values
          window.push value
          window.shift() if window.length > lookback

          index = 0
          results.push _.reduce window, (total, n) ->
            index++
            multiplier = index / _.sum [1..window.length]
            total + n * multiplier
          , 0
        results
      
      transform_movingAverage: (values, lookback) ->
        lookback = if lookback > 0 then lookback else 7
        results = []
        window = []
        for value in values
          window.push value
          window.shift() if window.length > lookback
          results.push _.sum(window) / window.length
        results

      dataChanged: ->
        rows = @applyTransform(@createDataFromJson(@data)).slice -@limit
        
Convert all values to 2 decimal points for readability
        
        for row in rows
          for column,index in row
            continue if index is 0
            row[index] = parseFloat(column.toFixed(2))
        
        @calculateTrendLine(rows) if @trendline
        @calculateValue(rows)
        @calculateChange(rows)
        console.log "Timeline #{@label}",rows

        columns = [ { "label": "Date", "type": "date" } ]
        series = []
        for property,index in @valueProperties
          columns.push { "label": property, "type": "number" }
          if index is 0
            s = { color: 'black' }
          else
            s = {}
          series.push s

        if @trendline
          columns.push { "label": "Trend", "type": "number" }
          series.push { color: '#aaa', lineDashStyle: [4, 2] }

        @$.chart.cols = columns
        @$.chart.options.series = series

        @$.chart.options.curveType = if @smooth is true then "function" else "none"
        @$.chart.options.isStacked = @isStacked 

        @$.chart.type = @type
        if (not @trendline and @$.chart.cols.length > 2) or (@trendline and @$.chart.cols.length > 3)
          @$.chart.options.legend.position = 'top'
          @$.chart.options.chartArea.top += 10
          @$.chart.options.series = []

        @$.chart.rows = rows

Pretty formatting of numbers

      decimalNumber: (value) ->
        numeral(value).format '0,0[.]00'
      
      percentage: (value) ->
        numeral(value).format '0,0.0%'
        
      absv: (value) ->
        Math.abs value
