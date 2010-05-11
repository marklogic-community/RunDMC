(: This script sets a document's status to either "Published" or "Draft". :)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

declare namespace map = "http://marklogic.com/xdmp/map";

let $map      := map:map()
let $params   := param:params()
let $action   := string($params[@name eq 'action'])
let $doc      := doc   ($params[@name eq 'path'])
let $redirect := string($params[@name eq 'redirect'])

let $status   := if ($action eq "Publish")   then "Published"
            else if ($action eq "Unpublish") then "Draft"
            else error((), "Parameter 'action' must be either 'Publish' or 'Unpublish'")

return
(
  (: Replace the existing document... :)
  xdmp:node-replace(
    $doc,
    (: ...with this incrementally transformed version :)
    xdmp:xslt-invoke("../model/set-doc-attribute.xsl", $doc, (map:put($map, "att-name",  "status"),
                                                              map:put($map, "att-value", $status),
                                                              $map))
  ),

  (: And return the user back to the page they started at :)
  xdmp:redirect-response($redirect)
)
