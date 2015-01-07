(: This script sets a document's status to either "Published" or "Draft". :)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";
import module namespace authorize="http://marklogic.com/rundmc/authorize"
        at "modules/authorize.xqy";

declare namespace map = "http://marklogic.com/xdmp/map";

let $map      := map:map()
let $params   := param:params()
let $action   := string($params[@name eq 'action'])
let $doc      := doc   ($params[@name eq 'path'])
let $redirect := string($params[@name eq 'redirect'])

let $status   := if ($action eq "Publish")   then "Published"
            else if ($action eq "Unpublish") then "Draft"
            else error((), "Parameter 'action' must be either 'Publish' or 'Unpublish'")

(: Ensure the user has the proper role in order to publish/unpublish :)
let $authorized :=
  if(authorize:is-admin()) then
    ()
  else
    error((), fn:concat("User is not authorized to ", $action, " ", $params[@name eq 'path']))

return
(
  (: Replace the existing document... :)
  xdmp:node-replace(
    $doc,
    (: ...with this incrementally transformed version :)
    xdmp:xslt-invoke("../model/publish-unpublish.xsl", $doc, (map:put($map, "att-name",  "status"),
                                                              map:put($map, "att-value", $status),
                                                              $map))
  ),

  (: And return the user back to the page they started at :)
  xdmp:redirect-response($redirect)
)
