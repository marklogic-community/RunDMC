import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "modules/queryparams.xqy";

let $params  := qp:load-params(),
    $comment-uri := concat('/private/comments/', current-dateTime(), '.xml'),
    $comment-doc := document {<ml:Comment
                      xmlns:ml="http://developer.marklogic.com/site/internal"
                      xmlns="http://www.w3.org/1999/xhtml"
                      status="Draft"
                      about="{$params/qp:about}.xml">
                      <ml:author> { string($params/qp:author)     }</ml:author>
                      <ml:created>{ current-dateTime()            }</ml:created>
                      <ml:url>    { string($params/qp:url)        }</ml:url>
                      <ml:body>   { xdmp:xslt-invoke(
                                      "cleanup-comment.xsl",
                                      xdmp:unquote(
                                        concat('<temp>',$params/qp:body,'</temp>'),
                                        "http://www.w3.org/1999/xhtml"
                                      )
                                    )                             }</ml:body>
                    </ml:Comment>
                    }
return
  (
    (: Create the draft comment document :)
    xdmp:document-insert($comment-uri,
                         $comment-doc),

    (: Send an email alert to the moderator :)
    xdmp:email(doc('/private/comment-moderation-email.xml')/*),

    (: Take the user back to the same page they commented on, and display an alert :)
    xdmp:redirect-response(concat($params/qp:about, '?commented=yes'))
  )
