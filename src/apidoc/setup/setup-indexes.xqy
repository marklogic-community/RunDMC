xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

let $config := admin:get-configuration()
let $dbid := xdmp:database()
return

(
try{
  let $rangespec :=
           admin:database-range-element-attribute-index("string",
           "http://marklogic.com/rundmc/api", "function", "", "lib",
           "http://marklogic.com/collation/", fn:false() )
  let $config := admin:database-add-range-element-attribute-index($config, $dbid, $rangespec)
  let $status := admin:save-configuration($config)
  return concat("Successfully added range index for api:function/@lib")
}
catch ($e) {
  if (data($e/error:code) eq "ADMIN-DUPLICATECONFIGITEM") then
  concat("Index for api:function/@lib already exists, skipping create")
  else $e
}

,

try{
  let $rangespec :=
           admin:database-range-element-attribute-index("string",
           "http://marklogic.com/rundmc/api", "function", "", "fullname",
           "http://marklogic.com/collation/", fn:false() )
  let $config := admin:database-add-range-element-attribute-index($config, $dbid, $rangespec)
  let $status := admin:save-configuration($config)
  return concat("Successfully added range index for api:function/@fullname")
}
catch ($e) {
  if (data($e/error:code) eq "ADMIN-DUPLICATECONFIGITEM") then
  concat("Index for api:function/@fullname already exists, skipping create")
  else $e
}

)
