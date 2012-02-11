xquery version "1.0-ml";

import module namespace param="http://marklogic.com/rundmc/params" at "modules/params.xqy";
import module namespace users="users" at "/lib/users.xqy";
import module namespace json="http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";

let $user := users:saveProfile(users:getCurrentUser(), param:params())

return json:serialize(
    json:object((
        "status", "ok",
        "name", $user/name/string()
    )) 
)
    
