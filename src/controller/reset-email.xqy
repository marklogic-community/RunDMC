xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";
declare namespace em="URN:ietf:params:email-xml:";

let $email := xdmp:get-request-field('email')
let $name := users:getUserByEmail($email)/name/string()

let $hostname := xdmp:hostname()

let $hostname := 
    if ($hostname = ("community.marklogic.com", "developer.marklogic.com")) then
        "developer.marklogic.com"
    else if ($hostname = ("stage-developer.marklogic.com", "dmc-stage.marklogic.com")) then
        "dmc-stage.marklogic.com"
    else if ($hostname = ("wlan31-12-236.marklogic.com", "dhcp141.marklogic.com")) then
        "localhost:8003"
    else
        "localhost:8008"

let $_ := xdmp:set-response-content-type("text/html")

let $_ := if ($name) then

    let $token := users:generateResetToken($email)
    let $url := concat("https://", $hostname, "/reset?t=", xdmp:url-encode($token), "&amp;email=", xdmp:url-encode($email))
    let $_ := xdmp:log(concat("Sending a reset email to ", $email, " with token ", $token))

    let $_ := util:sendEmail(
        "MarkLogic Community",
        "community-requests@marklogic.com",
        false(),
        $name,
        $email,
        "MarkLogic Community",
        "community-requests@marklogic.com",
        "MarkLogic Community Password Reset",
<em:content>
You can use the URL below to reset the MarkLogic Community password associated with your email address.  
Please note that this URL can only be accessed once; you may need to request another password reset email 
if you have already clicked on the link below.

          { $url }

If you did not request this email, please ignore it.  And if you believe this is a malicious attempt,
please feel free to respond to this email.

Best,
The MarkLogic Community
</em:content>)

    return ()

else 
    let $_ := xdmp:log(concat("Ignoring reset request for ", $email))
    return ()
return xdmp:xslt-invoke("/view/page.xsl", doc('/people/reset-email.xml'), map:new((map:entry('email', $email))))
