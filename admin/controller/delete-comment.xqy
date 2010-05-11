(: This script deletes a Comment doc at the supplied path :)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

let $params := param:params()
let $comment-uri := $params[@name eq 'path']
let $comment-doc := doc($comment-uri)
return
(
  (: Only delete the document if it is indeed a Comment :)
  if ($comment-doc/*:Comment) then xdmp:document-delete($comment-uri)
                              else error("The supplied path is not a Comment doc"),

  (: Return the user directly back to the Comment listing section in the Admin UI :)
  xdmp:redirect-response("/blog#tbl_comments")
)
