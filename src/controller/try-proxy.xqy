(: proxies http requests to the try server. This fixes issue #347. :)
import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "modules/queryparams.xqy";

import module namespace srv="http://marklogic.com/rundmc/server-urls"
       at "/controller/server-urls.xqy";

declare namespace http = "xdmp:http";

let $params := qp:load-params()
let $uri := "http:" || $srv:try-server || $params/qp:path || "?" ||
  fn:string-join(
    for $p in $params/*[fn:not(self::qp:path)]
    return
      fn:local-name($p) || "=" || xdmp:url-encode(fn:string($p)),
    "&amp;")
let $response := xdmp:http-get($uri)
return
(
  xdmp:set-response-code($response[1]/http:code, $response[1]/http:message),
  xdmp:set-response-content-type($response[1]/http:headers/http:content-type),
  $response[2]
)

