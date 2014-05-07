xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";

(: Make sure the version param was specified :)
$stp:errorCheck,

(: Normalize the guide fragments and URLs,
 : and add a chapter list to the title doc.
 :)
xdmp:invoke("consolidate-guides.xqy"),

(: Copy all the image files referenced by the guides.
 : This can run independently.
 : Converting all the guides will take a long time anyway.
 : This has to start after consolidate-guides finishes.
 :)
xdmp:spawn(
  "copy-guide-images.xqy",
  (xs:QName('VERSION'), $api:version-specified)),

(: Convert each title and chapter doc into renderable XML. :)
xdmp:invoke("convert-guides.xqy"),

xdmp:log("[setup-guides.xqy] done")

(: apidoc/setup-guides.xqy :)