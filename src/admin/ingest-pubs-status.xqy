xquery version "1.0-ml";

import module namespace info = "http://marklogic.com/appservices/infostudio"  
     at "/MarkLogic/appservices/infostudio/info.xqy";

import module namespace infodev = "http://marklogic.com/appservices/infostudio/dev"  
     at "/MarkLogic/appservices/infostudio/infodev.xqy";

let $ticket := xdmp:get-request-field("t", "no-ticket")
let $_ := xdmp:set-response-content-type("text/plain") 
return 
    if ($ticket = 'no-ticket') then
        "Must specify ticket id"
    else
        info:ticket($ticket)


