xquery version "1.0-ml";

import module namespace param="http://marklogic.com/rundmc/params" at "modules/params.xqy";
import module namespace users="users" at "/lib/users.xqy";
import module namespace json="http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";

let $valid := users:validateParams(users:getCurrentUser(), param:distinct-trimmed-params())

return
    if ($valid eq "ok") then

        let $user := users:saveProfile(users:getCurrentUser(), param:distinct-trimmed-params())

        let $email := $user/*:email/string()

        let $_ := users:mkto-sync-lead($email, $user, "DMC Signup")

        return json:serialize(
            json:object((
                "status", "ok",
                "name", $user/name/string()
            ))
        )
    else
        json:serialize(
            json:object((
                "status", $valid
            ))
        )

