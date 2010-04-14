let $path            := xdmp:get-request-path()  (: E.g., "/news" :)
let $path-stripped   := if (ends-with($path,"/"))
                        then substring($path, 1, string-length($path) - 1) (: For stripping the trailing slash :)
                        else $path

let $doc-url         := concat($path,          ".xml")
let $doc-url2        := concat($path-stripped, ".xml")
let $orig-url        := xdmp:get-request-url()
let $query-string    := substring-after($orig-url, '?')

return
     if ($path eq "/")                   then concat("/controller/transform.xqy?src=/index&amp;", $query-string)
else if (starts-with($path,'/private/')
      or starts-with($path,'/admin/'))   then $orig-url
else if (doc-available($doc-url))        then concat("/controller/transform.xqy?src=", $path, "&amp;", $query-string)
else if (doc-available($doc-url2))       then concat("/controller/redirect.xqy?path=", $path-stripped) (: e.g., redirect /news/ to /news :)
                                         else $orig-url
