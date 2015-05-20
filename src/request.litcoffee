Request Cache

    request = require 'browser-request'
    
    module.exports = class RequestCache
      constructor: () ->
        @data = {}
        @observers = {}
      
      loadDataForUrlAsync: (url, next) ->
        if @data[url]
          console.log "Cache hit for #{url}"
          return @data[url]

        if not @observers[url]
          observers = @observers[url] = []
          options = { method: @method, url: url,  json: { relaxed: true }, withCredentials: true }
          request options, (err, response, json) =>
            return @observer(err, null) if err?
            @data[url] = json
            for observer in observers
              observer null, @data[url]
              console.log "Cache completed request for #{url}"
            delete @observers[url]

        @observers[url].push next
