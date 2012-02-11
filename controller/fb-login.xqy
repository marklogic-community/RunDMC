xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";
import module namespace json="http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";
import module namespace path="http://marklogic.com/mljson/path-parser" at "/lib/mljson/lib/path-parser.xqy";

let $signed_request := xdmp:get-request-field("signedRequest")
let $fb-id := xdmp:get-request-field("userID")

let $_ := xdmp:set-response-content-type("application/json")
let $data := users:validateFacebookSignedRequest($signed_request)
let $facebook-id := xdmp:get-request-field("facebookID")
let $name := xdmp:get-request-field("name")
let $email := xdmp:get-request-field("email")

return 

    if ($data) then
        
        let $_ := xdmp:log($data)

        return if (empty($email)) then
            '{"status": "Sorry, bad or corrupt communication from Facebook."}'
        else

        let $user := users:getUserByEmail($email)
        return 
            if ($user) then
                if ($user/facebook-id = ($facebook-id, "")) then
                    let $_ := users:updateUserWithFacebookID($user, $facebook-id)
                    let $_ := users:startSession($user)
                    return json:serialize(json:object(("status", "ok", "name", $user/name/string())))
                 
                else
                    '{"status": "Sorry, there is another Facebook user registered here that has your email address."}'
            else
                let $user := users:createUser($name, $email, (), $facebook-id, "off")
                let $_ := users:startSession($user)
                return json:serialize(json:object(("status", "ok", "name", $name)))
        
    else
        '{"status": "Sorry, bad or corrupt communication from Facebook."}'
    
