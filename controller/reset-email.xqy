xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";

let $email := xdmp:get-request-field('email')
let $token := users:getResetToken($email)
let $url := concat("http://developer.marklogic.com/reset?id=", xdmp:url-encode($email), "&amp;t=", xdmp:url-encode($token))
let $_ := xdmp:log(concat("Sending a reset email to ", $email, " with token ", $token))
let $_ := xdmp:set-response-content-type("text/html")

let $_ := util:sendEmail(
    "MarkLogic Community",
    "community-requests@marklogic.com",
    (),
    (),
    $email,
    "MarkLogic Community",
    "community-requests@marklogic.com",
    "Password reset",
    concat("You can use the URL below to reset the MarkLogic Community password associated with your email address.  If you
did not request this email, please ignore it.

        ", $url, "

    Sincereley yours,
    The MarkLogic Community")
)

return <html><script type="text/javascript"><![CDATA[
               window.location = "/";
        ]]></script></html>

    
