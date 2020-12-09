xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";
import module namespace json="http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";
import module namespace jwt = "http://developer.marklogic.com/lib/jwt" at "/lib/jwt.xqy";

let $token := xdmp:get-request-field('token')
(: WARN: creates a new person document if needed :)
let $user := users:get-jwt-profile($token)
let $_ := xdmp:set-session-field('current-user', $user)
let $data :=
  if ($user) then
    (: WARN: this creates/modifies an existing document based on the id specified above :)
    let $_ := users:startSession($user)
    return 
      json:serialize(json:object(("status", "ok", "name", $user/name/string())))
  else
    '{"status": "Invalid token received"}'
return (
  xdmp:add-response-header("Location", "/"),
  xdmp:set-response-code(301, xdmp:quote($data))
)
