let $uri := xdmp:get-request-field("uri","")
let $normalized-uri := lower-case($uri)

return
(       if (ends-with($normalized-uri,".jpg")) then xdmp:set-response-content-type("image/jpeg")
   else if (ends-with($normalized-uri,".gif")) then xdmp:set-response-content-type("image/gif")
   else if (ends-with($normalized-uri,".html")) then xdmp:set-response-content-type("text/html")
   else if (ends-with($normalized-uri,".txt")) then xdmp:set-response-content-type("text/plain")
   else if (ends-with($normalized-uri,".css")) then xdmp:set-response-content-type("text/css")
   else if (ends-with($normalized-uri,".js")) then xdmp:set-response-content-type("text/javascript") (: who knows :)
   else if (ends-with($normalized-uri,".pdf")) then xdmp:set-response-content-type("application/pdf")
   else if (ends-with($normalized-uri,".png")) then xdmp:set-response-content-type("image/png")
   else ()
   ,
   let $doc := fn:doc($uri)
   return if ($doc) then $doc else xdmp:set-response-code(404, "Not found")
)
