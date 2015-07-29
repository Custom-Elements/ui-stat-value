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
        @valueProperties = []
        @properties = []
        @label = null
        @labels = [ ]
        @reduction = ''
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
        
      ready: ->
        @processValueProperties()

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
            format: "#,####{if @units.length > 2 then ' ' else ''}#{@units}"
            textStyle:
              color: '#aaa'
            baselineColor: '#aaa'
          hAxis:
            textStyle:
              color: '#aaa'
            baselineColor: '#aaa'

        # defer loading data until other attributes processed
        if @data?.length > 0
          @chartdata = @data

      labelPropertyChanged: ->
        @labels = [ @label ]

property handlers
        
      srcChanged: ->
        @loading = true
        request = window.ui_stats_cache ?= new RequestCache()
        request.loadDataForUrlAsync @src, @method, (err, json) =>
          @loading = false
          if err
            console.log "Error loading data from #{@src}", err
          else
            @chartdata = @onLoadHandler JSON.parse JSON.stringify(json)

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

      reductionChanged: ->
        @trendline = true if @reduction is 'trend'

      processValueProperties: ->
        @valueProperties = @valueProperty if @valueProperty?.length > 0
        
        if typeof @valueProperties is 'string'
          vp = _.map @valueProperties.split(','), (value) -> value.trim()
        else
          vp = @valueProperties
          
        @propertyFunctions = {}
        @properties = _.map vp, (propertyString) =>
          [property, expression] = propertyString.split '='
          property = property.trim()
          expression ?= "#{property}"
          expression = "with (this) { return #{expression} }"
          @propertyFunctions[property] = new Function expression
          property
        @properties ?= []

      labelsChanged: ->
        if typeof @labels is 'string'
          @labels =  _.map @labels.split(','), (value) -> value.trim()

deprecated properties

      functionChanged: ->
        @reduction = @function
        
other stuff
      
      createDataFromJson: (json) ->
        # defaults to all properties
        if @properties.length is 0
          @valueProperties = []
          item = _.first json
          for key of item
            if key isnt @dateProperty
              @valueProperties.push key
          @processValueProperties()

        values = _.map json, (item) =>
          dateObject = moment(item[@dateProperty], @datePattern).toDate()
          row = [ dateObject ]
          
          for property in @properties
            f = @propertyFunctions[property].bind(item)
            row.push parseFloat f()
          row

sort by date ascending, in case they come in out of order

        sortedValues = _.sortBy values, (a, b) ->
          momentA = moment a[0]
          momentB = moment b[0]
          momentA.diff momentB

filter data by date ranges

        if @since? or @until?
          sinceMoment = if @since? then @parseTime @since, -1 else moment '1970-01-01'
          untilMoment = if @until? then @parseTime @until, +1 else moment '2112-12-31'
          
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
          for propertyName, index in @properties
            values = _.map items, (array) -> parseFloat array[index + 1]
            value = @applyReductionFunction @groupByFunction, values
            result.push value
          result
          
      calculateTrendLine: (rows) =>
        # todo deal with multiple series? just uses first for now, maybe trendline=2
        series = 1
        offset = _.first(rows)[0].getTime()
        xValues = _.map rows, (array) -> array[0].getTime() - offset
        yValues = _.map rows, (array) -> array[series]
        trendFunction = lsq(xValues, yValues)
        _.each rows, (array, index) ->
          array.push trendFunction(xValues[index])

      calculateValue: (rows) ->
        # todo deal with multiple series? just uses first for now
        if @reduction is ''
          @reduction = if @trendline then 'trend' else 'last'
        series = if @reduction is 'trend' then @properties.length + 1 else 1
        values = _.map rows, (row) -> row[series]
        @value = @applyReductionFunction @reduction, values
            
      calculateChange: (rows) ->
        series = if @trendline then @properties.length + 1 else 1
        if rows.length < 2
          return @change = 0
        values = _.map rows, (row) -> row[series]
        initialValue = _.first values
        currentValue = _.last values
        previousValue = values[values.length - 2]
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
          when 'trend'
            _.last data
          else
            _.sum data

      applyTransform: (rows) ->
        return rows if @transformFunction is 'none'
        
        if @transformFunction in [ 'movingAverage', 'weightedMovingAverage', 'cumulative']
          transformFunction = eval "this.transform_#{@transformFunction}"
        else
          transformFunction = eval @transformFunction

        transformed = {}
        for propertyName, propertyIndex in @properties
          values = _.map rows, (row) -> row[propertyIndex + 1]
          transformed[propertyName] = transformFunction values, @transformArgs
        rowIndex = 0
        _.map rows, (row) =>
          result = [ row[0] ]
          for propertyName in @properties
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

      chartdataChanged: ->
        rows = @applyTransform(@createDataFromJson(@chartdata).slice -@limit)
        @calculateTrendLine(rows) if @trendline
        
Convert all values to 2 decimal points for readability
        
        for row in rows
          for column,index in row
            continue if index is 0
            row[index] = parseFloat(column.toFixed(2))
        
        @calculateValue(rows)
        @calculateChange(rows)
        console.log "Timeline #{@label}",rows

        columns = [ { "label": "Date", "type": "date" } ]
        series = [ ]
        for property,index in @properties
          label = if @labels[index] then @labels[index] else property
          columns.push { "label": label, "type": "number" }
          if index is 0 and @properties.length is 1
            series.push { color: 'black' }
          else
            series.push {}

        if @trendline
          columns.push { "label": "Trend", "type": "number" }
          series.push { color: '#aaa', lineDashStyle: [4, 2] }
          console.log "Trend", series, columns

        @$.chart.cols = columns
        @$.chart.options.series = series

        @$.chart.options.curveType = if @smooth is true then "function" else "none"
        @$.chart.options.isStacked = @isStacked 
        @$.chart.type = @type
        
        # show legend if we have more than one property
        if @properties.length > 1
          @$.chart.options.legend.position = 'top'
          @$.chart.options.chartArea.top += 10

        @$.chart.rows = rows

Pretty formatting of numbers

      decimalNumber: (value) ->
        numeral(value).format '0,0[.]00'
      
      percentage: (value) ->
        numeral(value).format('0,0.0%').replace('%','')
        
      absv: (value) ->
        Math.abs value

Formatting of relative times, like +30d, -3m

      parseTime: (value, rounding) ->
        match = /(\+|\-)(\d+)(d|m|y|w|h)/.exec value
        if not match?
          return moment value, @datePattern
        sign = match[1]
        qty = parseFloat match[2]
        qty *= -1 if sign is "-"
        units = switch match[3]
          when 'd'
            'days'
          when 'w'
            'weeks'
          when 'h'
            'hours'
          when 'm'
            'months'
          when 'y'
            'years'
        m = moment().add qty, units
        if rounding < 0
          m = m.add(rounding, units).endOf(units)
        if rounding > 0
          m = m.add(rounding, units).startOf(units)
        return m
