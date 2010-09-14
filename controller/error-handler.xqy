xquery version "1.0-ml";

import module namespace util = "http://markmail.org/util" at "/lib/util.xqy";
import module namespace prop = "http://xqdev.com/prop" at "/lib/properties.xqy";
import module namespace qp   = "http://www.marklogic.com/ps/lib/queryparams" at "modules/queryparams.xqy";

declare variable $error:errors as node()* external;

declare function local:renderErrors()
{
    let $newline := '
'

    for $e in $error:errors
    return
        (
        concat($newline, string($e/error:format-string), $newline),
        for $f in $e/error:stack/error:frame
            return concat("in ", string($f/error:uri), ", on line: ", string($f/error:line), $newline)
        )
};


let $_ := util:expireInSeconds(0)  (: error page :)
let $params  := qp:load-params()

let $error := xdmp:get-response-code()[1]
let $errorMessage := xdmp:get-response-code()[2]

let $_ := xdmp:add-response-header("content-type", "text/html")

return
  xdmp:xslt-invoke("/view/page.xsl", doc("/error.xml"),
    map:map(
      <map:map xmlns:map="http://marklogic.com/xdmp/map">
        <map:entry>
          <map:key>params</map:key>
          <map:value>{ $params }</map:value>
        </map:entry>
        <map:entry>
          <map:key>error</map:key>
          <map:value>{ $error }</map:value>
        </map:entry>
        <map:entry>
          <map:key>errorMessage</map:key>
          <map:value>{ $errorMessage }</map:value>
        </map:entry>
        <map:entry>
          <map:key>errors</map:key>
          <map:value>{ $error:errors }</map:value>
        </map:entry>
        <map:entry>
          <map:key>errorDetail</map:key>
          <map:value>{ local:renderErrors() }</map:value>
        </map:entry>
      </map:map>
    )
  )

