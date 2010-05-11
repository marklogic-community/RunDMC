import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

let $params  := param:params()

let $path            := xdmp:get-request-path()

let $doc-url         := concat('/admin', $path, ".xml")
let $orig-url        := xdmp:get-request-url()
let $query-string    := substring-after($orig-url, '?')

return

     if (starts-with($path,'/media/'))   then concat("/controller/get-db-file.xqy?uri=", $path)

else if ($path eq "/")                   then concat("/admin/controller/transform.xqy?src=/admin/index")
else if ($path eq
       "/admin/controller/create.xqy")   then let $new-doc-url := concat($params[@name eq '~uri_prefix'],
                                                                         $params[@name eq '~new_doc_slug'],
                                                                         '.xml')
                                         return
                                         if (not(doc-available($new-doc-url))) then concat($orig-url,
                                                                                          "?~new_doc_url=",
                                                                                          $new-doc-url)
                                         else concat("/admin/controller/transform.xqy?src=/admin", $params[@name eq '~edit_form_url'], "&amp;~orig_path=",
                                                                                        $params[@name eq '~edit_form_url'], "&amp;~doc_already_exists=yes")
else if (doc-available($doc-url))        then concat("/admin/controller/transform.xqy?src=/admin", $path, "&amp;", $query-string, "&amp;~orig_path=", $path)
                                         else $orig-url
