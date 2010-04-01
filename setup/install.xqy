xquery version "1.0-ml";

import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

let $src-dir := "/space/rundmc/"

let $config := admin:get-configuration()
let $forest-name := "RunDMCForest"
let $database-name := "RunDMCDatabase"
let $http-server-name := "RunDMCHTTP"
let $http-server-port := 8003
let $webdav-server-name := "RunDMCWebDAV"
let $webdav-server-port := 8005
let $groupid := admin:group-get-id($config, "Default")

return ( 
try {
	let $forest-create-config := admin:forest-create($config,$forest-name,xdmp:host(),())
	let $status := admin:save-configuration($forest-create-config)
	return string-join(("Succesfully created",$forest-name)," ")
}
catch ($e) {
	if (data($e/error:code) eq "ADMIN-DUPLICATENAME") then 
	fn:string-join(("Forest",$forest-name,"exists,","skipping create")," ")
	else $e
},
try { 
	let $database-create-config := admin:database-create($config, $database-name, xdmp:database("Security"), xdmp:database("Schemas"))
	let $status := admin:save-configuration($database-create-config)
	return string-join(("Succesfully created",$database-name)," ")
}
catch ($e) {
	if (data($e/error:code) eq "ADMIN-DUPLICATENAME") then 
	fn:string-join(("Database",$database-name,"exists,","skipping create")," ")
	else $e
},
try {
	let $forest-attach-config := admin:database-attach-forest($config,xdmp:database("RunDMCDatabase"),xdmp:forest("RunDMCForest"))
	let $status := admin:save-configuration($forest-attach-config)
	return string-join(("Succesfully attached",$forest-name,"to",$database-name)," ")
}
catch ($e) {
	if (data($e/error:code) eq "ADMIN-DATABASEFORESTATTACHED") then 
	fn:string-join(("Forest",$forest-name,"is already attached to",$database-name,",","skipping attach")," ")
	else $e
},
try {
	let $appserver-create-config := admin:http-server-create($config, $groupid, $http-server-name, 
    		$src-dir, $http-server-port, 0, xdmp:database($database-name))
	let $status := admin:save-configuration($appserver-create-config)
	return string-join(("Succesfully created",$http-server-name)," ")
}
catch ($e) {
	if (data($e/error:code) eq "ADMIN-PORTINUSE") 
		then fn:string-join(("Port for",$http-server-name,"in use, try changing the port number")," ")
	else (if (data($e/error:code) eq "ADMIN-DUPLICATEITEM") 
		then fn:string-join(("App Server",$http-server-name,"already exists on different port")," ") else $e)
},
try {
	let $webdav-create-config := admin:webdav-server-create($config, $groupid, $webdav-server-name, 
        	"/", $webdav-server-port, xdmp:database($database-name))
	let $status := admin:save-configuration($webdav-create-config)
	return string-join(("Succesfully created",$webdav-server-name)," ")
}
catch ($e) {
	if (data($e/error:code) eq "ADMIN-PORTINUSE") 
		then fn:string-join(("Port for",$webdav-server-name,"in use, try changing the port number")," ")
	else (if (data($e/error:code) eq "ADMIN-DUPLICATEITEM") 
		then fn:string-join(("WebDAV Server",$webdav-server-name,"already exists on different port")," ") else $e)
}
)