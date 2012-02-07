xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";

let $email := xdmp:get-request-field('email')
let $password := xdmp:get-request-field('password')
let $_ := xdmp:log(concat($email, " ", $password))
let $_ := xdmp:set-response-content-type("application/json")
let $user := users:checkCreds($email, $password)

return 

    if ($user) then

        let $_ := users:startSession($user)
        return 
        (: todo encode json :)
            concat( '{"status": "ok", "name": "', $user/name, '" }' )
    else
        '{"status": "Bad email/password combination"}'
    
