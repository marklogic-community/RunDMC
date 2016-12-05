xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";

declare option xdmp:mapping "false";

declare variable $REQUEST := xdmp:get-request-method();

if ($REQUEST = "GET") then
  users:get-prefs-as-json(users:getCurrentUser())
else if ($REQUEST = "POST") then
  let $setting := xdmp:get-request-field("setting")
  let $value := xdmp:get-request-field("value")
  return
    try {
      users:set-preference(users:getCurrentUser(), $setting, $value),
      "success"
    } catch ($e) {
      if ($e/error:name = "NO-USER") then
        xdmp:set-response-code(401, $e/error:code/fn:string())
      else if ($e/error:name = "INVALID-PREFERENCE") then
        xdmp:set-response-code(400, $e/error:code/fn:string())
      else
        xdmp:rethrow()
    }
else
  xdmp:set-response-code(405, "Method Not Allowed")
