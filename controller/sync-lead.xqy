xquery version "1.0-ml";

import module namespace mkto="mkto" at "../lib/marketo.xqy";
import module namespace cookies = "http://parthcomp.com/cookies" at "../lib/cookies.xqy";

let $email := xdmp:get-request-field('email')
let $asset := xdmp:get-request-field('asset')
let $cookie := cookies:get-cookie('_mkto_trk')[1]

let $_ :=

try {
    mkto:associate-lead-via-asset($email, $cookie, $asset)
} catch ($e)  {
    (xdmp:log(concat('mkto:associate-lead-via-asset failed ', $e/string())))
}

return "ok"
    
