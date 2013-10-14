xquery version "1.0-ml";

import module namespace srv = "http://marklogic.com/rundmc/server-urls" at "server-urls.xqy";
import module namespace users = "users" at "../lib/users.xqy";

let $_ := xdmp:set-response-content-type("application/json")

let $d := xdmp:get-request-field('download')
let $email := users:getCurrentUser()/email/string()
let $token := users:getDownloadToken($email)

return "{ status: 'ok', url: '" || $d || "?t=" || $token || '&amp;email=' || $email || "'}"
