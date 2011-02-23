import module namespace dates="http://xqdev.com/dateparser"
       at "../lib/date-parser.xqy";

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
   return if ($doc) 
    then 
        let $if-modified-since := xdmp:get-request-header("If-Modified-Since")
        let $last-modified := xs:dateTime(xdmp:document-get-properties($uri, xs:QName("prop:last-modified"))/string()) (: truncate to seconds ??:)
        let $last-modified := fn:adjust-dateTime-to-timezone($last-modified, xs:dayTimeDuration("PT0H")) 
        let $if-modified-since := 
            if ($if-modified-since) then
                (: Sat, 18 Dec 2010 01:10:43 GMT :)
                (: xdmp:parse-dateTime isn't ready for prime time :)
                (: xdmp:parse-dateTime("[FNn,*-3], [D01] [MNn,*-3] [Y0001] [h01]:[m01]:[s01] GMT", $if-modified-since) :)
                (: fn:adjust-dateTime-to-timezone(fn:adjust-dateTime-to-timezone(dates:parseDateTime($if-modified-since), ())) :)
                dates:parseDateTime($if-modified-since)
            else
                ()

        let $not-modified :=  if (empty($last-modified) or empty($if-modified-since)) 
            then
                false()
            else
                $last-modified le $if-modified-since

        (: let $_ := xdmp:add-response-header("X-Debug1", xs:string($last-modified)) :)
        (: let $_ := xdmp:add-response-header("X-Debug2", xs:string($if-modified-since)) :)

        let $last-modified-fmt := fn:format-dateTime($last-modified, 
                 "[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] GMT","en","AD","US")

        let $_ := xdmp:add-response-header("Last-Modified", $last-modified-fmt) 
        (: let $_ := xdmp:set-response-header("Expires", "3600") :)
        return if ($not-modified)
            then 
                xdmp:set-response-code(304, "Not modified")
            else 
                $doc 

    else 
        xdmp:set-response-code(404, "Not found")
)
