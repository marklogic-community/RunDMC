let $path            := xdmp:get-request-path()

let $doc-url         := concat('/admin', $path, ".xml")
let $orig-url        := xdmp:get-request-url()
let $query-string    := substring-after($orig-url, '?')

return

     if (starts-with($path,'/css/')
      or starts-with($path,'/images/')
      or starts-with($path,'/js/'))      then concat('/admin', $orig-url)

else if (starts-with($path,'/media/'))   then concat("/controller/get-db-file.xqy?uri=", $path)

else if ($path eq "/")                   then concat("/admin/transform.xqy?src=/admin/index")
else if (doc-available($doc-url))        then concat("/admin/transform.xqy?src=/admin", $path, "&amp;", $query-string)
                                         else $orig-url
