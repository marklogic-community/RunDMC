xquery version "1.0-ml";

import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

import module namespace srv = "http://marklogic.com/rundmc/server-urls" at "/controller/server-urls.xqy";

let $config := admin:get-configuration()
let $forest-name := "RunDMCForest"
let $database-name := "RunDMC"
let $raw-db-name := "RunDMC-api-rawdocs"
let $raw-db-forest := "RunDMC-api-rawdocs"
let $http-server-name := "RunDMC-standalone-api"
let $http-server-port := xs:int(tokenize($srv:standalone-api-server,':')[last()])
let $groupid := admin:group-get-id($config, "Default")
let $rewriter := "/apidoc/controller/url_rewrite.xqy"

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
        let $forest-attach-config := admin:database-attach-forest($config,xdmp:database($database-name),xdmp:forest($forest-name))
        let $status := admin:save-configuration($forest-attach-config)
        return string-join(("Succesfully attached",$forest-name,"to",$database-name)," ")
}
catch ($e) {
        if (data($e/error:code) eq "ADMIN-DATABASEFORESTATTACHED") then 
        concat("Forest ",$forest-name," is already attached to ",$database-name,", skipping attach")
        else $e
},

let $config := admin:database-set-uri-lexicon($config, xdmp:database($database-name), true())
let $status := admin:save-configuration($config)
return concat("Successfully enabled the URI lexicon on the ",$database-name," database.")

,

let $config := admin:database-set-collection-lexicon($config, xdmp:database($database-name), true())
let $status := admin:save-configuration($config)
return concat("Successfully enabled the collection lexicon on the ",$database-name," database.")

,

try {
        let $appserver-create-config := admin:http-server-create($config, $groupid, $http-server-name, 
                    xdmp:modules-root(), $http-server-port, 0, xdmp:database($database-name))
        let $status := admin:save-configuration($appserver-create-config)
        return string-join(("Succesfully created",$http-server-name)," ")
}
catch ($e) {
        if (data($e/error:code) eq "ADMIN-PORTINUSE") 
                then concat("Port ",$http-server-port," for ",$http-server-name," already in use; try changing the standalone-api-server port number in /config/server-urls.xml")
        else (if (data($e/error:code) eq "ADMIN-DUPLICATEITEM") 
                then fn:string-join(("App Server",$http-server-name,"already exists on different port")," ") else $e)
}
,
let $config := admin:appserver-set-url-rewriter(admin:get-configuration(), xdmp:server($http-server-name), $rewriter)
let $status := admin:save-configuration($config)
return concat("Successfully set http-server url rewriter to ",$rewriter)
,

let $this-server-id := xdmp:server()
let $set-db-config := admin:appserver-set-database($config, $this-server-id, xdmp:database($database-name))
let $status := admin:save-configuration($set-db-config)
return concat("Successfully associated the current server with the ",$database-name," database.")

,

try {
        let $forest-create-config := admin:forest-create($config,$raw-db-forest,xdmp:host(),())
        let $status := admin:save-configuration($forest-create-config)
        return concat("Succesfully created ",$forest-name)
}
catch ($e) {
        if (data($e/error:code) eq "ADMIN-DUPLICATENAME") then 
        concat("Forest ",$raw-db-forest," exists, skipping create")
        else $e
},

try{
        let $raw-db-config := admin:database-create($config, $raw-db-name, xdmp:database("Security"), xdmp:database("Schemas"))
        let $status := admin:save-configuration($raw-db-config)
        return concat("Successfully created the ",$raw-db-name," database.")
}
catch ($e) {
        if (data($e/error:code) eq "ADMIN-DUPLICATENAME") then
        concat("Database ",$raw-db-name," exists, skipping create")
        else $e
}
,

try {
        let $forest-attach-config := admin:database-attach-forest($config,xdmp:database($raw-db-name),xdmp:forest($raw-db-forest))
        let $status := admin:save-configuration($forest-attach-config)
        return concat("Succesfully attached ",$raw-db-forest," to ",$raw-db-name)
}
catch ($e) {
        if (data($e/error:code) eq "ADMIN-DATABASEFORESTATTACHED") then 
        concat("Forest ",$raw-db-forest," is already attached to ",$raw-db-name,", skipping attach")
        else $e
},

"Setting up indexes...",
xdmp:invoke("/apidoc/setup/setup-indexes.xqy", (), <options xmlns="xdmp:eval">
                                                     <database>{xdmp:database($database-name)}</database>
                                                   </options>)

)
