xquery version "1.0-ml";

import module namespace pubs='http://developer.marklogic.com/pubs' at './pubs.xqy';

let $version := xdmp:get-request-field("version", "no-version")
let $_ := xdmp:set-response-content-type("text/html") 
return 
    if ($version = 'no-version') then
        "Must specify version query string"
    else
        pubs:load-dir(concat("/space/pubs/", $version))
