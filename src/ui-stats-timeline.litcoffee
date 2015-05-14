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
        @function = 'average'
        @groupByFunction = 'sum'
        @units = ''
        @limit = Number.MAX_VALUE
        @value = ''
        @smooth = true
        @type = 'line'

      domReady: ->
        @$.chart.options =
          legend: { position: 'none' }
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
              fontSize: 8
            baselineColor: '#aaa'
          hAxis:
            textStyle:
              color: '#aaa'
              fontSize: 9
            baselineColor: '#aaa'

      srcChanged: ->
        @loading = true
        options = { method: 'POST', url: @src,  json: { relaxed: true }, withCredentials: true }
        request options, (err, response, json) =>
          if not err?
            @data = json
          else
            console.log "Error loading data", err
          @loading = false
      
      createDataFromJson: (json) ->
        @applyGrouping _.map json, (item) =>
          dateObject = moment(item[@dateProperty], @datePattern).toDate()
          value = item[@valueProperty]
          [ dateObject, value ]
          
      applyGrouping: (arrayOfArrays) ->
        return arrayOfArrays if not @groupBy?
        grouped = _.groupBy arrayOfArrays, (array) =>
          moment(array[0]).startOf(@groupBy).format(@datePattern)
        _.map grouped, (items, date) =>
          dateObject = moment(date, @datePattern).toDate()
          values = _.map items, (array) -> array[1]
          value = @applyReductionFunction @groupByFunction, values
          [ dateObject, parseFloat value.toFixed(2) ]
          
      calculateValue: (data) ->
        values = _.map data, (array) -> array[1]
        value = @applyReductionFunction @function, values
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

        @$.chart.options.curveType = if @smooth is true then "function" else "none"
        @$.chart.type = @type

        @$.chart.rows = rows
