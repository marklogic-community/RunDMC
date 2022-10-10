xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";
declare namespace em="URN:ietf:params:email-xml:";

(: either this is ok, because we have a session, or because t matches email :)
let $email := xdmp:get-request-field('email')
let $token := xdmp:get-request-field('t', 'missing')
let $user := users:getCurrentUser()

let $has-session := if ($user) then true() else false()

let $user := if ($has-session) then $user else users:getUserByEmail($email)

return if ($has-session or ($token eq $user/reset-token/string())) then
    let $_ := if ($has-session) then
        xdmp:log(concat("Reset password for email (", $email, ") with token ", $token))
    else
        xdmp:log(concat("Reset password for email (", $email, ")"))

    (: make a new reset token, expiring the current one :)
    let $id := $user/id/string()
    let $token := if ($has-session) then ()
      else users:getResetToken($user/email/string())
    let $params  := (
                       <param name="token">{ $token }</param>,
                       <param name="id">{ $id }</param>,
                       <param name="has-session">{ $has-session }</param>
                    )

    (: embed the id and token in the new form :)
    return
    xdmp:xslt-invoke("/view/page.xsl", doc('/people/reset.xml'),
        map:map(
        <map:map xmlns:map="http://marklogic.com/xdmp/map">
            <map:entry>
            <map:key>params</map:key>
            <map:value>{ $params }</map:value>
            </map:entry>
        </map:map>
        )
    )


else
    let $_ := xdmp:set-response-content-type("text/html")
    let $_ := xdmp:log(concat("Reset password for email (", $email, ") failed with token: ", $token))
    return if ($has-session) then
        <html><script type="text/javascript"><![CDATA[ window.location = "/people/profile"; ]]></script></html>
    else
        <html><script type="text/javascript"><![CDATA[ window.location = "/"; ]]></script></html>

