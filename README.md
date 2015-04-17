# ui-stats

## Summary

`ui-stats` is a series of polymer components which allow you to quickly and easily create a statusboard to track whatever it is you need to track. Data can be loaded explicitly, programmatically, or more commonly via URL. Different components can generate different types of tiles for displaying different types of data.


## Installation and Usage

Install the `ui-stats` polymer component

    npm install --save Custom-Elements/ui-stats.git
    
Import polymer, easiest to use the shared instance, but locally is fine too.

```html
<link rel="import" href="https://services.glgresearch.com/ui-toolkit/polymer.html">
```
    
Import the `ui-stats` component and the `font-awesome` component stylesheet, which must be imported at the root DOM.

```html
<link rel="import" href="node_modules/ui-stats/ui-stats.html">
<link rel="stylesheet" href="node_modules/ui-font-awesome/font-awesome.less">
```

Here's a starting template that puts it all together.

```html
<!DOCTYPE html>
<html>
  <head>
    <link rel="import" href="https://services.glgresearch.com/ui-toolkit/polymer.html">    
    <link rel="import" href="node_modules/ui-stats/ui-stats.html">
    <link rel="stylesheet" href="node_modules/ui-font-awesome/font-awesome.less">
  </head>

  <body>
    <ui-stats-number value="55">
    </ui-stats>
  </body>

</html>
```

## ui-stats-number

The Number tile is focused on the display of a metric that can be represented by a single number, along with associated secondary metrics, such as a comparison to the previous value or a sparkline. For example:

![screenshot](images/screenshot1.png)

Data can be provided in one of several ways:

* Via the `value` attribute, which specifies a single value:

  ```html
  <ui-stats-number value="55">
  </ui-stats>
  ```

* Via the `values` attribute, which takes an array of values:

  ```html
  <ui-stats-number values="[5, 10, 15, 20, 25]">
  </ui-stats>
  ```

  Or an array of quoted JSON objects, which requires use of the `property` attribute to specify which property is your primary metric.

  ```html
  <ui-stats-number property="count" values="[{'date':'2014-03-01', 'count':10}, {'date':'2014-03-02', 'count':15}, {'date':'2014-03-03', 'count':11}]">
  </ui-stats>
  ```

* Via the `src` attribute, passing in the URL to a resource containing the data, in JSON format. This option also requires the `property` attribute. JSON is loaded from the URL and assigned to the `values` attribute. Note that this is a client side call, and requires CORS if it's not hitting the same server.

  ```html
  <ui-stats-number property="count" src="http://example.com/data.json">
  </ui-stats>
  ```

The layout of the tile is automatically configured by the type of data you pass into it, with the following behaviors.

* If you set the `value` attribute to a single value, that value will be used as the primary display metric, overriding any other ways of setting that value, such as loading the data from a URL.

* If you set the `values` attribute to a single value, it is the same as setting the `value` attribute.

* If you set the `values` attribute to exactly two values, the first value will be used as the primary metric, and the second value will be considered the previous value for that metric. A percent change will automatically be shown in this case. If you want to display the previous value, rather than the change, set the `absolute` attribute to `true`.

* If you set the `values` attribute to three or more values, a primary metric will be displayed and a sparkline of the values will be generated. By default the last element of the array will be the primary metric, but this can be controlled via the `operation` attribute. If you only want to consider a subset of the values, set the `maxValues` attribute to truncate the list to the last `maxValues` elements. For example, the following src returns 365 days of data, but we only care about the last 7 days.
  
  ```html
  <ui-stats-number name="CM Applications (7 days)" 
    src="https://query.glgroup.com/councilApplicant/getStats.mustache"
    property="applied" maxValues="7">
  </ui-stats>
  ```

### Attributes

prefix

operation
