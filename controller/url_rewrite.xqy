import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "../model/filter-drafts.xqy";

let $path            := xdmp:get-request-path()  (: E.g., "/news" :)

let $path-redir   := 
    if (ends-with($path,"/")) then 
        substring($path, 1, string-length($path) - 1) (: For stripping the trailing slash :)
    else if (starts-with($path, '/blog') and ends-with($path, '.xqy')) then 
        substring($path, 1, string-length($path) - 4)
    else if ($path = ("/download", "/downloads")) then
        "/products"
    else 
        $path

let $latest-prod-uri := "/products/marklogic-server/4.1"

let $path            := 
    if ($path eq "/products") then
        $latest-prod-uri 
    else 
        $path

let $doc-url         := concat($path,       ".xml")
let $doc-url2        := concat($path-redir, ".xml")
let $orig-url        := xdmp:get-request-url()
let $query-string    := substring-after($orig-url, '?')

return
     if ($path eq "/")                  then concat("/controller/transform.xqy?src=/index&amp;", $query-string)
else if (starts-with($path,'/media/'))   then concat("/controller/get-db-file.xqy?uri=", $path)
else if (starts-with($path,'/pubs/'))   then concat("/controller/get-db-file.xqy?uri=", $path)
else if (starts-with($path,'/private/')
      or starts-with($path,'/admin/'))  then $orig-url
else if (doc-available($doc-url) and
         draft:allow(doc($doc-url)/*))  then concat("/controller/transform.xqy?src=", $path, "&amp;", $query-string)
else if (doc-available($doc-url2) and
         draft:allow(doc($doc-url2)/*)) then concat("/controller/redirect.xqy?path=", $path-redir) (: e.g., redirect /news/ to /news :)
                                        else $orig-url
