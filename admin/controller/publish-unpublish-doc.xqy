import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

declare namespace map = "http://marklogic.com/xdmp/map";

let $params   := param:params()
let $action   := string($params[@name eq 'action'])
let $doc      := doc($params[@name eq 'path'])
let $redirect := string($params[@name eq 'redirect'])

let $status   := if ($action eq "Publish")   then "Published"
            else if ($action eq "Unpublish") then "Draft"
            else error((), "Parameter 'action' must be either 'Publish' or 'Unpublish'")

let $map      := map:map()
return
(
  map:put($map, "att-name",  "status"),
  map:put($map, "att-value", $status),

  xdmp:node-replace(
    $doc,
    xdmp:xslt-invoke("../model/set-doc-attribute.xsl", $doc, $map)
  ),

  xdmp:redirect-response($redirect)
)
