import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "/modules/queryparams.xqy";

let $params  := qp:load-params(),
    $comment-uri := concat('/private/comments/', current-dateTime(), '.xml'),
    $comment-doc := document {<ml:Comment
                      xmlns:ml="http://developer.marklogic.com/site/internal"
                      xmlns="http://www.w3.org/1999/xhtml"
                      status="Pending"
                      about="{$params/qp:about}">
                      <ml:author>{ string($params/qp:author)     }</ml:author>
                      <ml:date>  { current-dateTime()            }</ml:date>
                      <ml:url>   { string($params/qp:url)        }</ml:url>
                      <ml:body>  { xdmp:unquote(
                                     concat('<temp>',$params/qp:body,'</temp>'),
                                     "http://www.w3.org/1999/xhtml"
                                   )/*/node()                    }</ml:body>
                    </ml:Comment>
                    }
return
  (
    xdmp:document-insert($comment-uri,
                         $comment-doc,
                         xdmp:default-permissions(),
                         "http://developer.marklogic.com/content-collection"), (: The collection association doesn't appear to be working - why not?:)
    xdmp:redirect-response(concat($params/qp:about, '?message=Thank you for your comment. It has been submitted for moderation.'))
  )
