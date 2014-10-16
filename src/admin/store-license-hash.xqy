xquery version "1.0-ml";


xdmp:document-insert("/private/license-hash.xml",

<license>
     <hash>{xdmp:get-request-field("hash")}</hash>
     <id>{xdmp:get-request-field("id")}</id>
</license>

)
