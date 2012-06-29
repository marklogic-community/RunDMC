xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

for $file in xdmp:filesystem-directory(concat(xdmp:modules-root(),"/apidoc/config/images/"))
             /*:entry[*:type eq 'file']
let $doc := xdmp:document-get($file/*:pathname),
    $uri := concat("/media/apidoc/",$api:version,"/admin-help/images/",$file/*:filename)
return
(
  xdmp:log(concat("Inserting ",$uri)),
  xdmp:document-insert($uri,$doc)
),

"Done inserting admin help images."
