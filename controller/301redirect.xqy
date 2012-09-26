import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "modules/queryparams.xqy";

let $params := qp:load-params()
return
(
  xdmp:set-response-code(301,"Moved Permanently"),
  xdmp:add-response-header("Location",$params/qp:path)
)
