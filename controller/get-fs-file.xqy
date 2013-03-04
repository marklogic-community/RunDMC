import module namespace dates="http://xqdev.com/dateparser"
       at "../lib/date-parser.xqy";
import module namespace u="http://marklogic.com/rundmc/util"
       at "../lib/util-2.xqy";

let $path := xdmp:get-request-field("path","")
let $lower-path := lower-case($path)
let $_ := xdmp:add-response-header("Expires", "Thu, 01 Jan 1970 00:00:00 GMT")

return
(       if (ends-with($lower-path,".jpg")) then xdmp:set-response-content-type("image/jpeg")
   else if (ends-with($lower-path,".gif")) then xdmp:set-response-content-type("image/gif")
   else if (ends-with($lower-path,".html")) then xdmp:set-response-content-type("text/html")
   else if (ends-with($lower-path,".txt")) then xdmp:set-response-content-type("text/plain")
   else if (ends-with($lower-path,".css")) then xdmp:set-response-content-type("text/css")
   else if (ends-with($lower-path,".js")) then xdmp:set-response-content-type("text/javascript") (: who knows :)
   else if (ends-with($lower-path,".pdf")) then xdmp:set-response-content-type("application/pdf")
   else if (ends-with($lower-path,".png")) then xdmp:set-response-content-type("image/png")
   else ()
   ,
   let $doc := u:get-doc($path)
   return if ($doc) 
    then 
        let $_ := xdmp:add-response-header("Content-Length", string(u:get-doc-length($path)))
        return $doc 
    else 
        (xdmp:set-response-code(404, "Not found"), "404 Not Found")
)
