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
        @groupByFunction = 'average'
        @units = ''
        @limit = Number.MAX_VALUE
        @value = ''

      domReady: ->
        @$.chart.options =
          xbackgroundColor: 'yellow'
          legend: { position: 'none' }
          series: [ color: 'black' ]
          vAxis:
            format: "#,####{@units}"
            
      srcChanged: ->
        @loading = true
        options = { method: 'POST', url: @src,  json: { relaxed: true }, withCredentials: true }
        request options, (err, response, json) =>
          if not err?
            @data = @createDataFromJson(json).slice -@limit
            @calculateValue(@data)
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
          console.log "items", items
          dateObject = moment(date, @datePattern).toDate()
          values = _.map items, (array) -> array[1]
          value = @applyReductionFunction @groupByFunction, values
          [ dateObject, value ]
          
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
        console.log "reduce", f, data
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
          else
            _.sum data
        
      dataChanged: ->
        console.log "Timeline #{@label}", @data
        @$.chart.rows = @data
