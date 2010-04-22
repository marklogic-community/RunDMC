import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "../model/filter-drafts.xqy";

(:
TODO: redir /code/#proj to /code/proj
TODO: redir /code#proj to /code/proj

/howto/tutorials/2004-07-jsptags.xqy /learn/jsp
/howto/tutorials/2004-09-cisapache.xqy
/howto/tutorials/2004-09-dates.xqy
/howto/tutorials/2005-01-stylusstudio.xqy
/howto/tutorials/2006-04-mlsql.xqy
/howto/tutorials/2006-05-mljam-protocol.xqy
/howto/tutorials/2006-05-mljam.xqy
/howto/tutorials/2006-06-oxygen-xml-editor.xqy
/howto/tutorials/2006-06-recordloader.xqy
/howto/tutorials/2006-07-performancemeters.xqy
/howto/tutorials/2006-08-xqsync.xqy
/howto/tutorials/2006-09-paginated-search.xqy
/howto/tutorials/2006-09-triggers.xqy
/howto/tutorials/2007-04-schema.xqy
/howto/tutorials/2007-08-images.xqy
/howto/tutorials/2009-01-get-started-apps-2.xqy
/howto/tutorials/2009-01-get-started-apps.xqy
/howto/tutorials/2009-07-search-api-walkthrough.xqy
/howto/tutorials/2009-11-xsltforms-walkthrough.xqy

default.xqy
/howto/tutorials/technical-overview.xqy

/howto/tutorials/2006-08-xqsync-images
/howto/tutorials/2006-06-oxygen-images
/howto/tutorials/2006-05-mljam-images
/howto/tutorials/2009-01-get-started-apps-images
/howto/tutorials/2005-01-stylusstudio-images
/howto/tutorials/2006-04-mlsql-images
/howto/tutorials/2009-01-get-started-apps-2_files
/howto/tutorials/2009-07-search-api-walkthrough_files
/howto/tutorials/2004-09-cisapache_proxy-images
:)
let $path            := xdmp:get-request-path()  (: E.g., "/news" :)

let $path-redir   := 
    if (ends-with($path,"/")) then 
        substring($path, 1, string-length($path) - 1) (: For stripping the trailing slash :)
    else if (starts-with($path, '/blog') and ends-with($path, '.xqy')) then 
        substring($path, 1, string-length($path) - 4)
    else if ($path = ("/download", "/downloads")) then
        "/products"
    else if ($path = ("/blog/smallchanges", "/blog/smallchanges/", "/columns/smallchanges", "/columns/smallchanges/")) then
        "/blog"
    else if ($path = ("/cloudcomputing")) then
        "/products/server-for-ec2"
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
else if ($path != $path-redir) then concat("/controller/redirect.xqy?path=", $path-redir) 
else                                    $orig-url
