xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";

let $_ := users:endSession()

return '{"status": "ok"}'
