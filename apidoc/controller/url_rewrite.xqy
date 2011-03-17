let $path         := xdmp:get-request-path()
let $orig-url     := xdmp:get-request-url()
let $query-string := substring-after($orig-url, '?')
let $doc-url      := concat('/apidoc', $path, ".xml")
  
return

(: "/" means "/index.xml" (inside /apidoc) :)
if ($path eq '/') then 
  "/apidoc/controller/transform.xqy?src=/apidoc/index"
(: Respond with DB contents for /media :)
else if (starts-with($path, '/media/')) then 
   concat("/controller/get-db-file.xqy?uri=", $path)
(: If doc is found, then transform it :)
else if (doc-available($doc-url)) then 
  concat("/apidoc/controller/transform.xqy?src=/apidoc", $path, "&amp;", $query-string)
(: remove version from the URL for versioned assets :)
else if (matches($path, '^/(js|css|images|media)/v-[0-9]*/.*'))  then 
    replace($path, '/v-[0-9]*', '')
else
    $orig-url
