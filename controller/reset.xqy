xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";
declare namespace em="URN:ietf:params:email-xml:";

let $id := xdmp:get-request-field('id')
let $token := xdmp:get-request-field('token', 'missing')

let $user := users:getUserByID($id)
return if ($token eq $user/reset-token/string()) then
    let $_ := xdmp:log(concat("Reset password for email (", $email, ") with token ", $token))

    (: make a new reset token, expiring the one that got send here :)
    let $token := users:getResetToken($user/email/string())
    let $params  := (
                       <param name="token">{ $token }</param>,
                       <param name="id">{ $id }</param>
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
    return <html><script type="text/javascript"><![CDATA[
                   window.location = "/";
            ]]></script></html>

    
else ()
