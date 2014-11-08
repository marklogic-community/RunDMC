xquery version "1.0-ml";

import module namespace srv = "http://marklogic.com/rundmc/server-urls" at "server-urls.xqy";
import module namespace users = "users" at "../lib/users.xqy";
import module namespace json="http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";

let $_ := xdmp:set-response-content-type("application/json")

let $d := xdmp:get-request-field('download')
let $email := users:getCurrentUser()/email/string()
let $token := users:getDownloadToken($email)
let $path   := $d || "?t=" || xdmp:url-encode($token) || '&amp;email=' || xdmp:url-encode($email)

return json:serialize(
    json:object((
        "status", "ok",
        "path", $path
    ))
) 
