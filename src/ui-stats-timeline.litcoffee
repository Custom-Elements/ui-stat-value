    _ = require 'lodash'
    moment = require 'moment'
    request = require 'browser-request'
    numeral = require 'numeral'

    Polymer 'ui-stats-timeline',
    
      created: ->
        @pattern = "YYYY-MM-DD"
        @data = []
        @loading = false
        @xproperty = 'date'
        @yproperty = 'value'
        @groupByFunction = 'average'
        @units = ''
        @limit = Number.MAX_VALUE
        @value = ''
        @function = 'average'
        
      domReady: ->
        @$.chart.options =
          legend: { position: 'none' }
          series: [
            color: 'black'
          ]
          vAxis:
            format: "#,####{@units}"
            
      srcChanged: ->
        @loading = true
        options = { method: 'POST', url: @src,  json:{ relaxed: true }, withCredentials: true }
        request options, (err, response, json) =>
          if not err?
            @data = @createDataFromJson(json).slice -@limit
            @calculateValue(@data)
          else
            console.log "Error loading data", err
          @loading = false
      
      createDataFromJson: (json) ->
        @applyGrouping _.map json, (item) =>
          return [
            moment(item[@xproperty], @pattern).toDate() 
            item[@yproperty]
          ]        
          
      applyGrouping: (arrayOfArrays) ->
        return arrayOfArrays if not @groupBy?
        
        grouped = _.groupBy arrayOfArrays, (array) =>
          moment(array[0]).startOf(@groupBy).format(@pattern)
        _.map grouped, (values, date) =>
          sum  = _.sum values, (array) -> array[1]
          value = switch @groupByFunction
            when 'average'
              sum / values.length
            else
              sum
          [
            moment(date, @pattern).toDate()
            value
          ]
          
      calculateValue: (data) ->
        sum  = _.sum data, (array) -> array[1]
        value = switch @function
          when 'average'
            sum / data.length
          else
            sum
        @value = switch @units
          when '%'
            numeral(value * 100).format '0.0'
          else
            numeral(value).format '0,0[.]00'


        
      dataChanged: ->
        console.log "timeline", @data
        @$.chart.rows = @data
