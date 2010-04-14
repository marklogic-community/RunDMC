declare namespace ml = "http://developer.marklogic.com/site/internal";
let $path            := xdmp:get-request-path()  (: E.g., "/news" :)

let $path-redir   := 
    if (ends-with($path,"/")) then 
        substring($path, 1, string-length($path) - 1) (: For stripping the trailing slash :)
    else if (starts-with($path, '/blog') and ends-with($path, '.xqy')) then 
        substring($path, 1, string-length($path) - 4)
    else 
        $path

let $latest-blog-uri := (
    for $i in doc()/ml:Post/ml:created
    order by $i descending
    return base-uri($i)
)[1]
let $latest-blog-uri := substring($latest-blog-uri, 1, string-length($latest-blog-uri) - 4)
let $latest-prod-uri := "/products/marklogic-server/4.1"

let $path            := 
    if ($path eq "/products") then 
        $latest-prod-uri 
    else if ($path eq "/blog") then 
        $latest-blog-uri 
    else $path

let $doc-url         := concat($path,       ".xml")
let $doc-url2        := concat($path-redir, ".xml")
let $orig-url        := xdmp:get-request-url()
let $query-string    := substring-after($orig-url, '?')

return
     if ($path eq "/")                   then concat("/controller/transform.xqy?src=/index&amp;", $query-string)
else if (starts-with($path,'/private/')
      or starts-with($path,'/admin/'))   then $orig-url
else if (doc-available($doc-url))        then concat("/controller/transform.xqy?src=", $path, "&amp;", $query-string)
else if (doc-available($doc-url2))       then concat("/controller/redirect.xqy?path=", $path-redir) (: e.g., redirect /news/ to /news :)
                                         else $orig-url
