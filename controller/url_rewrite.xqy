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

declare function local:redir($path as xs:string) as xs:string
{
    let $path            := xdmp:get-request-path()  
    let $orig-url        := xdmp:get-request-url()

    return
    (: permanent redirs :)
    if ($path = ("/blog/smallchanges", "/blog/smallchanges/", "/columns/smallchanges", "/columns/smallchanges/")) then
        "/blog"
    else if (starts-with($path, "/columns")) then
        concat("/blog", substring($orig-url, 9))
    else if (starts-with($path, "/howto")) then
        concat("/learn", substring($orig-url, 7))
    else if ($path = ("/cloudcomputing")) then
        "/products/server-for-ec2"
    else if (starts-with($path, '/blog') and ends-with($path, '.xqy')) then 
        substring($path, 1, string-length($path) - 4)
    else
        $path
};

declare function local:rewrite($path as xs:string) as xs:string
{
    let $orig-url        := xdmp:get-request-url()
    let $query-string    := substring-after($orig-url, '?')
    let $doc-url         := concat($path, ".xml")
    let $latest-prod-uri := "/products/marklogic-server/4.1"

    return

    (: Support /download[s] and map them and /productsto latest product URI :)
    if ($path = ("/download", "/downloads", "/products", "/product")) then
        concat("/controller/transform.xqy?src=", $latest-prod-uri, "&amp;", $query-string)
    (: Ignore these URLs :)
    else if (starts-with($path,'/private/') or starts-with($path,'/admin/')) then
        $orig-url
    (: Respond with DB contents for /media and /pubs :)
    else if (starts-with($path, '/media/')) then 
        concat("/controller/get-db-file.xqy?uri=", $path)
    else if (starts-with($path, '/pubs/')) then
        concat("/controller/get-db-file.xqy?uri=", $path)
    (: Respond with DB contents for XML files that exist :)
    else if (doc-available($doc-url) and draft:allow(doc($doc-url)/*)) then 
        concat("/controller/transform.xqy?src=", $path, "&amp;", $query-string)
    (: Support / as /index.xml; TBD other directory indexes :)
    else
        $orig-url
};

let $path            := xdmp:get-request-path()  
let $orig-url        := xdmp:get-request-url()
let $query-string    := substring-after($orig-url, '?')

return
    if ($path eq "/")  then
        concat('/controller/transform.xqy?src=/index&amp;', $query-string)
    else if (ends-with($path, '/')) then
        concat('/controller/redirect.xqy?path=', substring($path, 1, string-length($path) - 1), 
                if ($query-string and $query-string != "") then concat('?', $query-string) else "")
    else if (local:redir($path) != $path) then
        concat('/controller/redirect.xqy?path=', local:redir($path))
    else 
        local:rewrite($path)

