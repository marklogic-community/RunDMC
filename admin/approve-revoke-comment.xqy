import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "../controller/modules/queryparams.xqy";

let $params  := qp:load-params()
let $action := string($params/qp:action)
let $comment-doc := doc($params/qp:path)
return
(
  xdmp:node-replace(
    $comment-doc,
    xdmp:xslt-invoke("set-status.xsl", $comment-doc,
      map:map(
        <map:map xmlns:map="http://marklogic.com/xdmp/map">
          <map:entry>
            <map:key>status</map:key>
            <map:value>{
              if ($action eq "Approve") then "Published"
         else if ($action eq "Revoke")  then "Draft"
         else error((), "Parameter 'action' must be either 'Approve' or 'Revoke'")
              }</map:value>
          </map:entry>
        </map:map>
      )
    )
  ),
  xdmp:redirect-response("/blog#tbl_comments")
)
