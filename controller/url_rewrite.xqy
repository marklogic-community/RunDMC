import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "modules/queryparams.xqy";

let $params          := qp:load-params()
let $path            := xdmp:get-request-path()  (: E.g., "/news" :)
let $path-stripped   := if (ends-with($path,"/"))
                        then substring($path, 1, string-length($path) - 1) (: For stripping the trailing slash :)
                        else $path

let $doc-url         := concat($path,          ".xml")
let $doc-url2        := concat($path-stripped, ".xml")
let $query-string    := string-join(for $param in $params/qp:* return concat('&amp;',local-name($param),'=',$param),'')
let $orig-url        := concat($path, '?', $query-string)

return
     if ($path eq "/")                   then concat("/controller/transform.xqy?src=/index",             $query-string)
else if (starts-with($path,'/private/')
      or starts-with($path,'/admin/'))   then $orig-url
else if (doc-available($doc-url))        then concat("/controller/transform.xqy?src=",   $path,          $query-string)
else if (doc-available($doc-url2))       then concat("/controller/redirect.xqy?path=", $path-stripped, $query-string) (: e.g., redirect /news/ to /news :)
                                         else $orig-url
