let $path            := xdmp:get-request-path()                       (: E.g., "/news" :)
let $path-minus-last := substring($path, 1, string-length($path) - 1) (: For stripping the trailing slash :)
let $doc-url         := concat($path,            ".xml")
let $doc-url2        := concat($path-minus-last, ".xml")
return
     if ($path eq "/")             then        "/default.xqy?src=/index"
else if (doc-available($doc-url))  then concat("/default.xqy?src=", $path)
else if (doc-available($doc-url2)
     and ends-with($path,"/"))     then concat("/redirect.xqy?path=", $path-minus-last)
                                   else $path
