xquery version "1.0-ml";
import module namespace ooxml= "http://marklogic.com/openxml" 
               at "/MarkLogic/openxml/package.xqy";

import module namespace admin = "http://marklogic.com/xdmp/admin" 
		  at "/MarkLogic/admin.xqy";

let $config := admin:get-configuration()
let $groupid := admin:group-get-id($config, "Default")
let $app-server-root := admin:appserver-get-root($config,admin:appserver-get-id($config, $groupid, "RunDMCHTTP"))
let $zip-file := fn:concat($app-server-root,"admin/sample-db.zip")
let $dir := ""
let $pkg := xdmp:document-get($zip-file)
let $uris := ooxml:package-uris($pkg)
let $parts := ooxml:package-parts($pkg)
return ooxml:package-parts-insert($dir, $uris, $parts)

