import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "/modules/queryparams.xqy";

let $params          := qp:load-params()
let $path            := xdmp:get-request-path()  (: E.g., "/news" :)
let $path-stripped   := if (ends-with($path,"/"))
                        then substring($path, 1, string-length($path) - 1) (: For stripping the trailing slash :)
                        else $path

let $doc-url         := concat('/admin', $path,          ".xml")
let $doc-url2        := concat('/admin', $path-stripped, ".xml")
let $query-string    := string-join(for $param in $params/qp:* return concat('&amp;',local-name($param),'=',$param),'')

return
     if ($path eq "/")                   then concat("/admin/default.xqy?src=/admin/index",             $query-string)
else if (starts-with($path,'/private/')) then $path

else if (starts-with($path,'/css/')
      or starts-with($path,'/images/')
      or starts-with($path,'/js/'))      then concat('/admin',$path)

else if (doc-available($doc-url))        then concat("/admin/default.xqy?src=/admin",   $path,          $query-string)
else if (doc-available($doc-url2))       then concat("/redirect.xqy?path=", $path-stripped, $query-string) (: e.g., redirect /news/ to /news :)
                                         else $path
