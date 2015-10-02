xquery version "1.0-ml";

import module namespace util = "http://markmail.org/util" at "/lib/util.xqy";
import module namespace prop = "http://xqdev.com/prop" at "/lib/properties.xqy";
import module namespace qp   = "http://www.marklogic.com/ps/lib/queryparams" at "modules/queryparams.xqy";

declare namespace em="URN:ietf:params:email-xml:";

declare variable $error:errors as node()* external;

declare function local:renderErrors($summary)
{
    let $newline := '
'

    for $e in $error:errors
    return (
        concat($newline, string($e/error:format-string), $newline),
        if ($summary) then
            for $f in $e/error:stack/error:frame
            return concat("in ", string($f/error:uri), ", on line: ", string($f/error:line), $newline)
        else
            "error: " || xdmp:quote($e)
    )
};

let $error := xdmp:get-response-code()[1]
let $errorMessage := xdmp:get-response-code()[2]

let $ok := ($error le 401)

let $_ := if (not($ok))
    then
        (xdmp:add-response-header("content-type", "text/html"),
        util:expireInSeconds(0))
    else
        ()

let $params  := qp:load-params()

let $sendError := ($error ge 500)

let $hostname := xdmp:hostname()

let $staging := if ($hostname = "stage-developer.marklogic.com") then "Staging " else ""

let $address :=
    if ($hostname = ("community.marklogic.com", "developer.marklogic.com", "stage-developer.marklogic.com", "dmc-stage.marklogic.com")) then
        "dmc-admin@marklogic.com"
    else if ($hostname = ("wlan31-12-236.marklogic.com", "dhcp141.marklogic.com")) then
        "eric.bloch@marklogic.com"
    else
        ()

let $hostport   := concat($hostname, "")  (: fixme someday :)
let $uri        := concat(xdmp:get-request-protocol(), "://", $hostport, xdmp:get-request-url())
let $referer    := xdmp:get-request-header("Referer", "")[1]
let $location   := xdmp:get-request-header("Location", "")[1]
let $userAgent  := xdmp:get-request-header("User-agent", "")[1]

let $_ := if ($sendError and $address)
    then
        util:sendEmail(

            "RunDMC Alert",
            $address,
            false(),
            "RunDMC Admin",
            $address,
            "RunDMC Admin",
            $address,
            concat("RunDMC Error: ", $error, " ", $errorMessage, " on ", $hostname),
            <em:content>
        Status = { $error }
        URI = { $uri }
        User Agent = { $userAgent }
        Referrer = { $referer }
        Location = { $location }
        Details =
                   { local:renderErrors(fn:false()) }
        </em:content>
        )
    else
        ()

return
  try {
      if ($ok) then
        ($error, $errorMessage)
      else
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
              <map:value>{ local:renderErrors(fn:true()) }</map:value>
            </map:entry>
          </map:map>
        ))
    } catch ($e) {
        ($error, $errorMessage)
    }
