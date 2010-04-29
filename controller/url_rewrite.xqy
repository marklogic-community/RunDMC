import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "../model/filter-drafts.xqy";

(:
TODO:
/conference/2007
default.xqy
/news/standards/w3c.xqy
:)

declare function local:redir($path as xs:string) as xs:string
{
    let $path            := xdmp:get-request-path()  
    let $orig-url        := xdmp:get-request-url()

    return
    (: permanent redirs :)
    if ($path = ("/blog/smallchanges", "/blog/smallchanges/", "/columns/smallchanges", "/columns/smallchanges/")) then
        "/blog"
    else if (starts-with($path, "/about")) then
        "/"
    else if (starts-with($path, "/xfaqtor")) then
        "/learn"
    else if (starts-with($path, "/default.xqy")) then
        "/"
    else if (starts-with($path, "/rss")) then
        "/blog/atom.xml?feed=blog"
    else if (starts-with($path, "/legal")) then
        "/"
    else if (starts-with($path, "/people")) then
        "/"
    else if (starts-with($path, "/svn")) then
        "/code"
    else if (starts-with($path, "/help")) then
        "/learn"
    else if (starts-with($path, "/user-groups")) then
        concat("/meet", substring($orig-url, 9))
    else if (starts-with($path, "/columns")) then
        concat("/blog", substring($orig-url, 9))
    else if (starts-with($path, "/howto/tutorials")) then
        concat("/learn", substring($orig-url, 17))
    else if (starts-with($path, "/howto")) then
        concat("/learn", substring($orig-url, 7))
    else if (ends-with($path, "/default.xqy")) then
        substring($path, 1, string-length($path)- 12)
    else if ($path = ("/cloudcomputing")) then
        "/products/server-for-ec2"
    else if ((starts-with($path, '/blog') or starts-with($path, '/learn')) and ends-with($path, '.xqy')) then 
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
    else if ($path = ("/blog/atom.xml")) then
        "/lib/atom.xqy?feed=blog"
    else if ($path = ("/newsandevents/atom.xml", "/news/atom.xml", "/events/atom.xml")) then
        "/lib/atom.xqy?feed=newsandevents"
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

