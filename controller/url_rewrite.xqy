import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "../model/filter-drafts.xqy";

import module namespace u = "http://marklogic.com/rundmc/util" at "../lib/util-2.xqy";

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
    else if ($path = ("/pubs", "/pubs/", "/pubs/4.1", "/pubs/4.1/")) then
        "/docs"
    else if ($path = ("/pubs/4.0", "/pubs/4.0/")) then
        "/docs/4.0"
    else if ($path = ("/pubs/3.2", "/pubs/3.2/")) then
        "/docs/3.2"
    else if ($path = ("/products/marklogic-server")) then
        "/products/marklogic-server/4.1"
    else if ($path = ("/download/4.1", "/download/4.1/")) then
        "/products/marklogic-server/4.1"
    else if ($path = ("/download/4.0", "/download/4.0/")) then
        "/products/marklogic-server/4.0"
    else if ($path = ("/download/3.2", "/download/3.2/")) then
        "/products/marklogic-server/3.2"
    else if ($path = ("/download/binaries/4.1/requirements.xqy")) then
        "/products/marklogic-server/requirements"
    else if ($path = ("/download/binaries/4.0/requirements.xqy")) then
        "/products/marklogic-server/requirements-4.0"
    else if ($path = ("/download/confirm.xqy")) then
        "/products"
    else if (starts-with($path, "/about")) then
        "/"
    else if (starts-with($path, "/pubs/3.1")) then
        replace($path, "/pubs/3.1", "/pubs/3.2")
    else if (starts-with($path, "/3.1")) then
        replace($path, "/3.1", "/pubs/3.2")
    else if (starts-with($path, "/4.0")) then
        replace($path, "/4.0", "/pubs/4.0")
    else if (starts-with($path, "/4.1")) then
        replace($path, "/4.1", "/pubs/4.1")
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
        concat("/code/", replace(substring($path, 6), "^([^/]*)/.*", "$1" ))
    else if (starts-with($path, "/help")) then
        "/learn"
    else if (starts-with($path, "/user-groups")) then
        concat("/meet", substring($orig-url, 13))
    else if (starts-with($path, "/columns")) then
        concat("/blog", substring($orig-url, 9))
    else if (starts-with($path, "/howto/tutorials")) then
        concat("/learn", substring($orig-url, 17))
    else if (starts-with($path, "/howto")) then
        concat("/learn", substring($orig-url, 7))
    else if (starts-with($path, "/%20howto/tutorials")) then
        concat("/learn", substring($orig-url, 20))
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
    (: should assert path does not end in / :)
    let $dir-url         := concat($path, "/")
    let $index-url       := concat($dir-url, "index.xml")
    let $latest-prod-uri := "/products/marklogic-server/4.1"

    return

    if ($path eq '/')  then 
        "/controller/transform.xqy?src=/index"
    (: Support /download[s] and map them and /productsto latest product URI :)
    else if ($path = ("/download", "/downloads", "/products", "/product")) then
        concat("/controller/transform.xqy?src=", $latest-prod-uri, "&amp;", $query-string)
    (: remove version from the URL for versioned assets :)
    else if (matches($path, '^/(js|css|images|media)/v-[0-9]*/.*'))  then 
        replace($path, '/v-[0-9]*', '')
    (: Ignore these URLs :)
    else if (starts-with($path,'/private/')) then
        $orig-url
    (: Deny access to the Admin site scripts from this server :)
    else if (starts-with($path,'/admin/')) then
        error((), "Access denied.")
    (: Respond with DB contents for /media and /pubs :)
    else if (starts-with($path, '/media/')) then 
        concat("/controller/get-db-file.xqy?uri=", $path)
    else if (starts-with($path, '/pubs/')) then
        concat("/controller/get-db-file.xqy?uri=", $path)
    (: Respond with DB contents for XML files that exist :)
    else if (doc-available($doc-url) and draft:allow(doc($doc-url)/*)) then 
        concat("/controller/transform.xqy?src=", $path, "&amp;", $query-string)
    (: Respond with DB contents for directories that have index.xml files :)
    else if (u:is-directory($dir-url) and doc-available($index-url)) then 
        concat("/controller/transform.xqy?src=", $index-url, "&amp;", $query-string)
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
    if (($path ne '/') and ends-with($path, '/')) then
        concat('/controller/redirect.xqy?path=', substring($path, 1, string-length($path) - 1), 
                if ($query-string and $query-string != "") then concat('?', $query-string) else "")
    else if (local:redir($path) != $path) then
        concat('/controller/redirect.xqy?path=', local:redir($path))
    else 
        local:rewrite($path)

