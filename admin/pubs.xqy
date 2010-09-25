xquery version "1.0-ml";

module namespace pubs='http://developer.marklogic.com/pubs'; 

declare function pubs:load-dir($dir as xs:string) {
    for $entry in xdmp:filesystem-directory($dir)//*:entry
    let $path := fn:string($entry/*:pathname)
    let $file := fn:string($entry/*:filename)
    let $type := fn:string($entry/*:type)
    let $uri := fn:substring($path, fn:string-length("/space/"))
    let $encoding := 
        if (fn:ends-with($file, ".js")) then
            "ISO-8859-1"
        else
            "UTF-8"

    let $format := 
        if (fn:ends-with($file, ".html")) then
            "xml"
        else
            if (fn:ends-with($file, ".css") or fn:ends-with($file, ".js")) then
                "text"
            else
                "binary"
    let $format := if (fn:contains($uri, "/javadoc/") and fn:ends-with($uri, ".html")) then
                       "text"
                   else
                       $format
    
    return
        if ($type eq 'directory') then
            (try {xdmp:directory-create(fn:concat($path, "/")) } catch ($e) {} ,
             xdmp:eval("
                xquery version '1.0-ml';
                import module  namespace pubs='http://developer.marklogic.com/pubs' at './admin/pubs.xqy';
                declare variable $dir as xs:string external;
                pubs:load-dir($dir)
             ", (xs:QName("dir"), $path)),
             ($path, <br/>))
        else
            (xdmp:document-load($path, 
                <options xmlns="xdmp:document-load">
                    <uri>{$uri}</uri>
                    <format>{$format}</format>
                    <repair>full</repair>
                    <encoding>{$encoding}</encoding>
                    <default-namespace>http://www.w3.org/1999/xhtml</default-namespace>
                </options>
            ), ($path, <br/>))
};
