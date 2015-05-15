    _ = require 'lodash'
    moment = require 'moment'
    request = require 'browser-request'
    numeral = require 'numeral'

    Polymer 'ui-stats-timeline',
    
      created: ->
        @label = "Timeline"
        @datePattern = "YYYY-MM-DD"
        @data = []
        @loading = false
        @dateProperty = 'date'
        @valueProperty = 'value'
        @valueProperties = [ 'value' ]
        @function = 'average'
        @groupByFunction = 'sum'
        @units = ''
        @limit = Number.MAX_VALUE
        @value = ''
        @smooth = true
        @type = 'line'
        method = 'GET'

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

      srcChanged: ->
        @loading = true
        options = { method: @method, url: @src,  json: { relaxed: true }, withCredentials: true }
        request options, (err, response, json) =>
          if not err?
            @data = json
          else
            console.log "Error loading data", err
          @loading = false
      
      createDataFromJson: (json) ->
        @applyGrouping _.map json, (item) =>
          dateObject = moment(item[@dateProperty], @datePattern).toDate()
          values = [ dateObject ]
          for property in @valueProperties
            values.push item[property]
          values
          
      applyGrouping: (arrayOfArrays) ->
        return arrayOfArrays if not @groupBy?
        grouped = _.groupBy arrayOfArrays, (array) =>
          moment(array[0]).startOf(@groupBy).format(@datePattern)
        _.map grouped, (items, date) =>
          dateObject = moment(date, @datePattern).toDate()
          result = [ dateObject ]
          for propertyName, index in @valueProperties
            values = _.map items, (array) -> array[index + 1]
            value = @applyReductionFunction @groupByFunction, values
            result.push parseFloat(value.toFixed(2))
          result

      calculateValue: (rows) ->
        seriesValues = []
        for propertyName, index in @valueProperties
          values = _.map rows, (row) -> row[index + 1]
          seriesValues.push @applyReductionFunction @function, values
        value = @applyReductionFunction @function, seriesValues
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
          when 'none'
            0
          else
            _.sum data
        
      dataChanged: ->
        rows = @createDataFromJson(@data).slice -@limit
        @calculateValue(rows)
        console.log "Timeline #{@label}",rows

        columns = [ { "label": "Date", "type": "date" } ]
        console.log "#{@label}", @valueProperties
        for property in @valueProperties
          columns.push { "label": property, "type": "number" }
        @$.chart.cols = columns

        @$.chart.options.curveType = if @smooth is true then "function" else "none"
        @$.chart.type = @type
        if @$.chart.cols.length > 2
          @$.chart.options.legend.position = 'top'
          @$.chart.options.chartArea.top += 10
          @$.chart.options.series = []

        @$.chart.rows = rows
