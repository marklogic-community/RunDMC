xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

let $config := admin:get-configuration()
let $dbid := xdmp:database("RunDMC")

let $rangespec :=
         admin:database-range-element-attribute-index("string",
         "http://marklogic.com/rundmc/api", "function", "", "lib",
         "http://marklogic.com/collation/", fn:false() )
let $config := admin:database-add-range-element-attribute-index($config, $dbid, $rangespec)

let $rangespec :=
         admin:database-range-element-attribute-index("string",
         "http://marklogic.com/rundmc/api", "function", "", "fullname",
         "http://marklogic.com/collation/", fn:false() )
let $config := admin:database-add-range-element-attribute-index($config, $dbid, $rangespec)

return admin:save-configuration($config)
