let $uri := xdmp:get-request-field("uri","")
let $normalized-uri := lower-case($uri)

return
(       if (ends-with($normalized-uri,".jpg")) then xdmp:set-response-content-type("image/jpeg")
   else if (ends-with($normalized-uri,".gif")) then xdmp:set-response-content-type("image/gif")
   else if (ends-with($normalized-uri,".png")) then xdmp:set-response-content-type("image/png")
   else ()
   ,
   fn:doc($uri)
)
