let $path            := xdmp:get-request-path()  (: E.g., "/news" :)
let $path-stripped   := if (ends-with($path,"/"))
                        then substring($path, 1, string-length($path) - 1) (: For stripping the trailing slash :)
                        else $path

let $doc-url         := concat($path,          ".xml")
let $doc-url2        := concat($path-stripped, ".xml")
return
     if ($path eq "/")                   then        "/default.xqy?src=/index"
else if (starts-with($path,'/private/')) then $path
else if (doc-available($doc-url))        then concat("/default.xqy?src=",   $path)
else if (doc-available($doc-url2))       then concat("/redirect.xqy?path=", $path-stripped) (: e.g., redirect /news/ to /news :)
                                         else $path
