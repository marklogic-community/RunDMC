xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";

let $id := xdmp:get-request-field('id')
let $user := users:getUserByID($id)
let $token := xdmp:get-request-field('token')
let $password := xdmp:get-request-field('s_password')
let $password-confirm := xdmp:get-request-field('s_password_confirm')

let $_ := if (($password eq $password-confirm) and $user/reset-token/string() eq $token)) then
    let $_ := xdmp:log(concat("Attempting to set password for ", $id))
    return users:setPassword($user, $password)
else 
    xdmp:log(concat("Bad validation for password reset for ", $id))

return
  xdmp:xslt-invoke("/view/page.xsl", doc('/index.xml'), map:map())
