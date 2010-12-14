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

let $host := xdmp:host-name(xdmp:host())
let $admin-host := 
    if ($host = "developer.marklogic.com") then
        "developer-admin.marklogic.com"
    else if ($host = "stage-developer.marklogic.com") then
        "dmc-stage-admin.marklogic.com"
    else 
        "unknown-admin"

let $email := 
<em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
  <rf:subject>New Comment submitted for moderation on {$host} </rf:subject>
  <rf:from>
    <em:Address>
      <em:name>MarkLogic Developer Community</em:name>
      <em:adrs>NOBODY@marklogic.com</em:adrs>
    </em:Address>
  </rf:from>
  <rf:to>
    <em:Address>
      <em:name>DMC Admin</em:name>
      <em:adrs>dmc-admin@marklogic.com</em:adrs>
    </em:Address>
  </rf:to>
<em:content>
     Pending comment is below:
     -----------------------
 
{xdmp:quote($comment-doc)}

     -----------------------

     Moderate this pending comment -> http://{$admin-host}/blog/comment-edit?~doc_path={$comment-uri} 

  </em:content>
</em:Message>


return
  (
    (: Create the draft comment document :)
    xdmp:document-insert($comment-uri,
                         $comment-doc),

    (: Send an email alert to the moderator :)
    xdmp:email($email),

    (: Take the user back to the same page they commented on, and display an alert :)
    xdmp:redirect-response(concat($params/qp:about, '?commented'))
  )
