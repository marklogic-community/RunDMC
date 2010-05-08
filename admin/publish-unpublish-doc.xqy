import module namespace param="http://marklogic.com/rundmc/params"
       at "../controller/modules/params.xqy";

let $params   := param:params()
let $action   := string($params[@name eq 'action'])
let $doc      := doc($params[@name eq 'path'])
let $redirect := string($params[@name eq 'redirect'])
return
(
  xdmp:node-replace(
    $doc,
    xdmp:xslt-invoke("set-status.xsl", $doc,
      map:map(
        <map:map xmlns:map="http://marklogic.com/xdmp/map">
          <map:entry>
            <map:key>status</map:key>
            <map:value>{
              if ($action eq "Publish") then "Published"
         else if ($action eq "Unpublish")  then "Draft"
         else error((), "Parameter 'action' must be either 'Publish' or 'Unpublish'")
              }</map:value>
          </map:entry>
        </map:map>
      )
    )
  ),
  xdmp:redirect-response($redirect)
)
