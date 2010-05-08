import module namespace param="http://marklogic.com/rundmc/params"
       at "../controller/modules/params.xqy";

let $params := param:params()
let $comment-uri := $params[@name eq 'path']
let $comment-doc := doc($comment-uri)
return
(
  if ($comment-doc/*:Comment) then xdmp:document-delete($comment-uri) else error("The supplied path is not a Comment doc"),
  xdmp:redirect-response("/blog#tbl_comments")
)
