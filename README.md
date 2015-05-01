# ui-stats

## Summary

`ui-stats` is a series of polymer components which allow you to quickly and easily create a statusboard to track whatever it is you need to track. Data can be loaded explicitly, programmatically, or more commonly via URL. Different components can generate different types of tiles for displaying different types of data.

Check out the [demo](https://services.glgresearch.com/ui-stats/)


## Installation and Usage

Install the `ui-stats` polymer component

```bash
    npm install --save Custom-Elements/ui-stats.git
```

Import polymer, easiest to use the shared instance, but locally is fine too.

```html
<link rel="import" href="https://services.glgresearch.com/ui-toolkit/polymer.html">
```
    
Import the `ui-stats` component.

```html
<link rel="import" href="node_modules/ui-stats/ui-stats.html">
```

The components currently require [polymer-serve](https://github.com/Custom-Elements/polymer-serve) to compile the less and coffeescript.

Here's a starting template that puts it all together.

```html
<!DOCTYPE html>
<html>
  <head>
    <link rel="import" href="https://services.glgresearch.com/ui-toolkit/polymer.html">    
    <link rel="import" href="node_modules/ui-stats/ui-stats.html">
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

* Via the `data` attribute, which takes an array of values:

  ```html
  <ui-stats-number data="[5, 10, 15, 20, 25]">
  </ui-stats>
  ```

  Or an array of quoted JSON objects, which requires use of the `property` attribute to specify which property is your primary metric.

  ```html
  <ui-stats-number property="count" data="[{'date':'2014-03-01', 'count':10}, {'date':'2014-03-02', 'count':15}, {'date':'2014-03-03', 'count':11}]">
  </ui-stats>
  ```

* Via the `src` attribute, passing in the URL to a resource containing an array of data, in JSON format. This option also requires the `property` attribute. JSON is loaded from the URL and assigned to the `data` attribute. Note that this is a client side call, and requires CORS if it's not hitting the same server. This is intended to be the the primary use case.

  ```html
  <ui-stats-number property="count" src="http://example.com/data.json">
  </ui-stats>
  ```

The layout of the tile is automatically configured by the type of data you pass into it, with the following behaviors.

* If you set the `value` attribute to a single value, that value will be used as the primary display metric, overriding any other ways of setting that value, such as loading the data from a URL.

* If you set the `data` attribute to a single value, it is the same as setting the `value` attribute.

* If you set the `data` attribute to exactly two values, the first value will be used as the primary metric, and the second value will be considered the previous value for that metric. A percent change will automatically be shown in this case. If you want to display the previous value, rather than the change, set the `absolute` attribute to `true`.

* If you set the `data` attribute to three or more values, a primary metric will be displayed and a sparkline of the values will be generated. By default the sum of the array will be the primary metric, but this can be controlled via the `function` attribute. If you only want to consider a subset of the values, set the `limit` attribute to truncate the list to the last `limit` elements. For example, the following URL returns 365 days of data in JSON format, but we only care about the last 7 days, and the "applied" property.
  
  ```html
  <ui-stats-number name="CM Applications (7 days)" 
    src="https://query.glgroup.com/councilApplicant/getStats.mustache"
    property="applied" limit="7">
  </ui-stats>
  ```

### Attributes

#### src

_&lt;URL&gt;_

URL containing data to populate `data`. Must be CORS accessible. Should return an array of JSON objects. Requires
the `property` value to specify which object property to use for the Y axis value.

#### property

_&lt;string&gt;_

Name of the property value to use for the Y axis when loading data via the `src` attribute

#### value

_&lt;integer&gt;_

Shortcut for assigning a single value, equivalent to passing a single value array to `data`

#### data

_&lt;Array&gt;_

Array of values, will be truncated to the last `limit` elements. If it contains two elements, you get change indicators, if three or more elements you get a sparkline.

#### limit

_&lt;integer&gt;_

Number of elements (from the end of the array) to use from `data`

#### function

_&lt;string&gt;_

Sets the reduction function to apply the data values to create the primary metric. The default values is `last` if there are two or less values and `sum` if there are more than two values. Possible values are: `first`, `last`, `sum`, `average`, `min`, `max`, `count`

#### name

_&lt;string&gt;_

Name of the stat, appears in the title bar.

#### absolute

_&lt;boolean&gt;_

When there are exactly 2 values present, show the absolute change in value, rather than a percentage change.

#### smooth

_&lt;boolean&gt;_

If `true`, applies smoothing to the sparkline.

#### prefix

_&lt;string&gt;_

String prepended to the metrics, for example `$` or `ms`.

## ui-stats-chart

Simplified wrapper around [Google Charts](https://developers.google.com/chart/) designed to display charts from JSON data.

### Attributes

#### src

_&lt;URL&gt;_

URL containing data to populate `data`. Must be CORS accessible. Should return an array of JSON objects. Requires
the `cols` value to specify which object property or properties to use for the Y axis value(s).

#### data

_&lt;Array&gt;_

Array of values, will be truncated to the last `limit` elements. Data can be an array of numbers, or objects, if you
specify the `cols` attribute to describe the data.

#### limit

_&lt;integer&gt;_

Number of elements (from the end of the array) to use from `data`

#### name

_&lt;string&gt;_

Name of the stat, appears in the title bar.

#### smooth

_&lt;boolean&gt;_

If `true`, applies smoothing to the sparkline.

#### cols

_&lt;Array&gt;_

JSON array describing the columns in the data. Uses the following properties. Columns are considered ordered
and you are expected to put dates in column 0 if generating a timeline chart.

  * `id`, property name
  * `type`, one of `date`, `string`, or `number`
  * `label`, name (defaults to id value)
  * `pattern`, only applies to dates, pattern for date parser, defaults to YYYY-MM-DD

### type

_&lt;string&gt;_

Type of chart to draw. Can be one of `pie`, `bar`, `column`, `line`, 'scatter', 'area'
