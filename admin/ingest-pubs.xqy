xquery version "1.0-ml";

import module namespace info = "http://marklogic.com/appservices/infostudio"  
     at "/MarkLogic/appservices/infostudio/info.xqy";

import module namespace infodev = "http://marklogic.com/appservices/infostudio/dev"  
     at "/MarkLogic/appservices/infostudio/infodev.xqy";

declare function local:process-file(
   $document as node(),
   $source-location as xs:string,
   $ticket-id as xs:string,
   $policy-deltas as element(info:options)?,
   $context as item()?)
as xs:string+
{
    let $root := $context//*:r
    let $version := $context//*:v
    let $dir := fn:concat($root, $version)
    let $literal := fn:concat("/pubs/", $version)

    let $encoding := 
        if (fn:ends-with($source-location, ".js")) then
            "ISO-8859-1"
        else
            "UTF-8"

    let $format := 
        if (fn:ends-with($source-location, ".html")) then
            "xml"
        else
            if (
                fn:ends-with($source-location, ".css") or 
                fn:ends-with($source-location, ".txt") or 
                fn:ends-with($source-location, ".") or 
                fn:ends-with($source-location, ".xqy") or 
                fn:ends-with($source-location, ".js")
               ) then
                "text"
            else
                "binary"
    let $format := if (fn:contains($source-location, "/javadoc/") and fn:ends-with($source-location, ".html")) then
                       "text"
                   else
                       $format

    let $delta :=
         <options xmlns="http://marklogic.com/appservices/infostudio">
             <format>{$format}</format>
             <encoding>{$encoding}</encoding>
             <uri>
                 <literal>{$literal}</literal>
                 <path>
                    { attribute strip-prefix { $dir } }
                 </path>
                 <literal>/</literal>
                 <filename/>
                 <dot-ext/>
             </uri>
         </options>
    
    return infodev:ingest($document,$source-location,$ticket-id,$delta)
};


declare function local:load-dir($root as xs:string, $version as xs:string) {
    
    let $ctxt := <c><r>{$root}</r><v>{$version}</v></c>
    let $dir := fn:concat($root, $version)

    let $annotation := <info:annotation>"Loading DMC docs"</info:annotation>
    let $ticket-id := infodev:ticket-create($annotation, "RunDMC", (), ())

    let $function := xdmp:function(xs:QName("local:process-file"))

    return (infodev:filesystem-walk($dir,$ticket-id,$function,(),$ctxt),concat("Ticket id: ", $ticket-id))
};

let $version := xdmp:get-request-field("version", "no-version")
let $_ := xdmp:set-response-content-type("text/html") 
return 
    if ($version = 'no-version') then
        "Must specify version query string"
    else
        local:load-dir("/Users/ebloch/pubs/", $version)
