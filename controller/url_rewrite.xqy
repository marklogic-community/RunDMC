import module namespace ml = "http://developer.marklogic.com/site/internal" at "../model/data-access.xqy";
import module namespace users = "users" at "../lib/users.xqy";
import module namespace u = "http://marklogic.com/rundmc/util" at "../lib/util-2.xqy";
import module namespace srv = "http://marklogic.com/rundmc/server-urls" at "server-urls.xqy";

(: TODO: handle old default.xqy URLs :)
declare function local:redir($path as xs:string) as xs:string
{
    let $path            := xdmp:get-request-path()  
    let $orig-url        := xdmp:get-request-url()

    return
    (: permanent redirs :)
    if ($path = ("/events", "/news", "/news-and-events",
                 "/blog/smallchanges", "/blog/smallchanges/", "/columns/smallchanges", "/columns/smallchanges/")) then
        "/blog"
    else if ($path eq "/learn/tutorials") then
        "/learn"
    else if ($path = ("/pubs", "/pubs/", "/docs")) then
        $srv:api-server
    else if ($path = ("/pubs/6.0", "/pubs/6.0/", "/docs/6.0")) then
        concat($srv:api-server,"/6.0")
    else if ($path = ("/pubs/5.0", "/pubs/5.0/", "/docs/5.0")) then
        concat($srv:api-server,"/5.0")
    else if ($path = ("/pubs/4.2", "/pubs/4.2/", "/docs/4.2")) then
        concat($srv:api-server,"/4.2")
    else if ($path = ("/pubs/4.1", "/pubs/4.1/", "/docs/4.1")) then
        concat($srv:api-server,"/4.1")
    else if ($path = ("/pubs/4.0", "/pubs/4.0/")) then
        $srv:api-server
    else if ($path = ("/pubs/3.2", "/pubs/3.2/")) then
        $srv:api-server

    else if (matches($path, "/pubs/[\d]\.[\d]/apidocs/")) then
        local:redirect-function-url($path)

    else if (matches($path, "/pubs/[\d]\.[\d]/books/")) then
        local:redirect-guide-url($path)

    else if (matches($path, "/pubs/[\d]\.[\d]/dotnet/")) then
        local:redirect-dotnet-url($path)
    (: use $orig-url in the javadoc redirects so it includes the query string :)
    else if (matches($path, "/pubs/[\d]\.[\d]/javadoc/")) then
        local:redirect-java-url($orig-url,"/javadoc/xcc/")
    else if (starts-with($path, "/pubs/5.0/hadoop/javadoc/")) then
        local:redirect-java-url($orig-url,"/javadoc/hadoop/")

    else if ($path = ("/download/6.0", "/download/6.0/")) then
        "/products/marklogic-server/6.0"
    else if ($path = ("/download/5.0", "/download/5.0/")) then
        "/products/marklogic-server/5.0"
    else if ($path = ("/download/4.2", "/download/4.2/")) then
        "/products/marklogic-server/4.2"
    else if ($path = ("/download/4.1", "/download/4.1/")) then
        "/products/marklogic-server/4.1"
    else if ($path = ("/download/4.0", "/download/4.0/")) then
        "/products/marklogic-server/4.0"
    else if ($path = ("/download/3.2", "/download/3.2/")) then
        "/products/marklogic-server/3.2"

    else if ($path = ("/products/sharepoint/1.0")) then
        "/products/sharepoint"

    else if ($path = ("/learn/sharepoint-install-guide")) then
        "/docs/sharepoint-connector/admin-guide"

    else if ($path = ("/download/binaries/6.0/requirements.xqy")) then
        "/products/marklogic-server/requirements-6.0"
    else if ($path = ("/download/binaries/5.0/requirements.xqy")) then
        "/products/marklogic-server/requirements-5.0"
    else if ($path = ("/download/binaries/4.2/requirements.xqy")) then
        "/products/marklogic-server/requirements-4.2"
    else if ($path = ("/download/binaries/4.1/requirements.xqy")) then
        "/products/marklogic-server/requirements-4.1"
    else if ($path = ("/download/binaries/4.0/requirements.xqy")) then
        "/products/marklogic-server/requirements-6.0"

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
    else if (starts-with($path, '/4.2')) then
        replace($path, "/4.2", "/pubs/4.2")
    else if (starts-with($path, '/5.0')) then
        replace($path, "/5.0", "/pubs/5.0")
    else if (starts-with($path, '/6.0')) then
        replace($path, "/6.0", "/pubs/6.0")
    else if (starts-with($path, "/xfaqtor")) then
        "/learn"
    else if (starts-with($path, "/default.xqy")) then
        "/"
    else if (starts-with($path, "/rss")) then
        "/blog/atom.xml"
    else if (starts-with($path, "/legal")) then
        "/"
    else if (starts-with($path, "/training")) then
        "/learn"
    else if (starts-with($path, "/svn")) then
        concat("/code/", replace(substring($path, 6), "^([^/]*)/.*", "$1" ))
    else if ($path = ("/code/comoms")) then
        "/code/marker"
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
    else if ($path = '/pubs/training/eclipse-xqdt-setup.pdf') then
        "/learn/xqdt-setup"
    else if ($path = '/learn/2009-01-get-started-apps') then
        "/learn/get-started-apps"
    else if ($path = '/learn/2009-01-get-started-apps-2') then
        "/learn/get-started-apps-2"
    else if ($path = '/events/markups-2010-09-11') then
        "/events/markups-2010-08-11"
    else if ($path = ("/try", "/try/ninja")) then
        "/try/ninja/index"
    else if ($path = ("/business-intelligence")) then
        "/products/odbc"
    else if ($path = ("/code/mlsql")) then
        "/code/mlsam"
    else if ($path = ("/learn/2006-04-mlsql")) then
        "/learn/2006-04-mlsam"
    else if ($path = ("/products/java-api")) then
        "/products/java"
    else if ($path = ("/learn/pojo-tutorial-01.zip")) then
        "/media/pojo-tutorial-01.zip"
    else if ($path = ("/guide/installation/procedures")) then
        "//docs.marklogic.com/guide/installation/procedures"
    else if (starts-with($path, "/discuss/")) then (: All discuss urls are gone for now :)
        "/discuss"
    else if (starts-with($path, "/people")) then (: All people urls are gone for now :)
        if ($path = ("/people/signup", "/people/reset", "/people/fb-signup", "/people/recovery", "/people/profile")) then (: except for these :)
            $path
        else
            "/people/supernodes"
    else
        $path
};

declare function local:redirect-dotnet-url($path as xs:string) as xs:string {
  let $file-name := tokenize($path,'/')[last()],
      $new-path  := concat("/dotnet/xcc/",$file-name)
  return
    concat($srv:api-server, $new-path)
};

declare function local:redirect-java-url($path as xs:string, $prefix as xs:string) as xs:string {
  let $file-path := substring-after($path, '/javadoc/'),
      $new-path  := concat($prefix,$file-path)
  return
    concat($srv:api-server, $new-path)
};

declare function local:redirect-function-url($path as xs:string) as xs:string {
  let $file-name := tokenize($path,'/')[last()],
      $mappings  := u:get-doc("/controller/api-redirects.xml")/mappings/mapping,
      $new-path  := $mappings[@from eq $file-name]/to/string(.)
  return
    concat($srv:api-server, $new-path)
};

declare function local:redirect-guide-url($path as xs:string) as xs:string {
  let $file-stem := substring-before(tokenize($path,'/')[last()], '.pdf'),
      $mappings  := u:get-doc("/apidoc/config/document-list.xml")/docs/*/guide,
      $new-stem  := $mappings[(@pdf-name,@source-name)[1] eq $file-stem]/@url-name/string(.)
  return
    concat($srv:api-server, '/guide/', $new-stem, '.pdf')
};

declare function local:gone($path as xs:string) as xs:boolean {
    $path = (
        "/products/marklogic-server/4.0",
        "/products/marklogic-server/requirements-4.0",
        "/docs/4.0",
        "/pubs/4.0",
        "/code/libmlxcc",
        "/code/versi",
        "/conference/2007",
        "/news/standards/w3c.xqy"
    )
};

(: if this is a server binary (and not xcc zip) you must be logged in or provide creds :)
declare function local:forbidden($path as xs:string) as xs:boolean {
    empty(users:getCurrentUser()) and not(users:authViaParams()) and not(ends-with($path, ".zip")) and
    (
     starts-with($path,'/download/binaries/6.0') or
     starts-with($path,'/download/binaries/5.0') or
     starts-with($path,'/download/binaries/4.2') or
     starts-with($path,'/download/binaries/4.1') or
     false()
    )
};

declare function local:rewrite($path as xs:string) as xs:string
{
    let $latest-version := "6.0"
    let $latest-sharepoint-connector-version := "1.1-1"

    (: Defaults for /docs and /producs :)
    let $latest-prod-uri := concat("/products/marklogic-server/", $latest-version)
    let $latest-doc-uri  := concat("/docs/", $latest-version)
    let $latest-requirements-uri  := concat("/products/marklogic-server/requirements-", $latest-version) 
    let $latest-xcc-uri  := concat("/products/xcc/", $latest-version) 

    let $latest-sharepoint-connector-doc-uri  := concat("/docs/sharepoint-connector/", $latest-sharepoint-connector-version) 

    let $path := if ($path = "/docs") then
        $latest-doc-uri
    else if ($path = "/products/marklogic-server") then
        $latest-prod-uri 
    else if ($path = "/products/marklogic-server/requirements") then
        $latest-requirements-uri
    else if ($path = "/products/xcc") then
        $latest-xcc-uri
    else 
        $path

    (: Could rework if/when this has more docs :)
    let $path := if ($path = "/docs/sharepoint-connector/admin-guide") then
        concat($latest-sharepoint-connector-doc-uri, "/admin-guide")
    else
        $path

    let $orig-url        := xdmp:get-request-url()
    let $query-string    := substring-after($orig-url, '?')
    let $doc-url         := concat($path, ".xml")
    (: should assert path does not end in / :)
    let $dir-url         := concat($path, "/")
    let $index-url       := concat($dir-url, "index.xml")

    return

    if (local:gone($path)) then
        "/controller/gone.xqy"
    else if (local:forbidden($path)) then
        "/controller/forbidden.xqy"
    else if ($path eq '/')  then 
        "/controller/transform.xqy?src=/index"
    (: Support /download[s] and map them and /products to latest product URI :)
    else if ($path = ("/download", "/downloads", "/products", "/product")) then
        concat("/controller/transform.xqy?src=", $latest-prod-uri, "&amp;", $query-string)
    else if ($path = ("/products/marklogic-server", "/products/marklogic-server/")) then
        concat("/controller/transform.xqy?src=", $latest-prod-uri, "&amp;", $query-string)
    (: remove version from the URL for versioned assets :)
    else if (matches($path, '^/(js|css|images|media|stackunderflow)/v-[0-9]*/.*'))  then 
        replace($path, '/v-[0-9]*', '')
    (: Ignore these URLs :)
    else if (starts-with($path,'/private/')) then
        $orig-url
    (: Respond with DB contents for /media and /pubs :)
    else if (starts-with($path, '/media/')) then 
        concat("/controller/get-db-file.xqy?uri=", $path)
    else if (starts-with($path, '/pubs/')) then
        concat("/controller/get-db-file.xqy?uri=", $path)
    (: Respond with DB contents for XML files that exist :)
    else if (doc-available($doc-url) and ml:doc-matches-dmc-page-or-preview(doc($doc-url))) then
        concat("/controller/transform.xqy?src=", $path, "&amp;", $query-string)
    (: Support /blog/atom.xml and some obsolete URLs we used to use for feeds :)
    else if ($path = ("/blog/atom.xml", "/newsandevents/atom.xml", "/news/atom.xml", "/events/atom.xml")) then
        "/lib/atom.xqy"
    else if ($path eq "/updateDisqusThreads") then
        "/controller/get-updated-disqus-threads.xqy"
    else if ($path eq "/invalidateNavigationCache") then
        "/controller/invalidate-navigation-cache.xqy"
    else if ($path eq "/validate") then
        concat("/controller/validate.xqy?", $query-string)
    else if ($path eq "/process-license-request") then
        concat("/controller/process-license-request.xqy?", $query-string)
    else if ($path eq "/process-license-request-2") then
        concat("/controller/process-license-request-2.xqy?", $query-string)
    else if ($path eq "/license-record") then
        concat("/controller/license-record.xqy?", $query-string)
    else if ($path eq "/signup") then
        "/controller/signup.xqy"
    else if ($path eq "/fb-login") then
        "/controller/fb-login.xqy"
    else if ($path eq "/login") then
        "/controller/login.xqy"
    else if ($path eq "/logout") then
        "/controller/logout.xqy"
    else if ($path eq "/set-password") then
        "/controller/set-password.xqy"
    else if ($path eq "/reset-email") then
        "/controller/reset-email.xqy"
    else if ($path eq "/reset") then
        concat("/controller/reset.xqy?", $query-string)
    else if ($path eq "/save-profile") then
        "/controller/save-profile.xqy"
    else if ($path eq "/enable-corn") then
        "/controller/enable-corn.xqy?q=on"
    else if ($path eq "/disable-corn") then
        "/controller/enable-corn.xqy"
    else if (starts-with($path, "/rex/")) then
        concat("/controller/rex.xqy?path-and-query=", xdmp:url-encode(concat(replace($path, "/rex", ""), "?", $query-string)))
    (: Control the visibility of files in the code base :)
    else if (not(u:get-doc("/controller/access.xml")/paths/prefix[starts-with($path,.)])) then
        "/controller/notfound.xqy"
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
        concat('/controller/301redirect.xqy?path=', local:redir($path))
    else 
        local:rewrite($path)

