xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "../model/data-access.xqy";

import module namespace setup="http://marklogic.com/rundmc/api/setup"
  at "common.xqy";

import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";

(: Make sure the version param was specified :)
$setup:errorCheck,

(: Copy all the image files referenced by the guides.
 : This can run independently.
 : Converting all the guides will take a long time anyway.
 :)
xdmp:spawn(
  "copy-guide-images.xqy",
  (xs:QName('VERSION'), $api:version)),

(: Normalize the guide fragments and URLs,
 : and add a chapter list to the title doc.
 :)
xdmp:invoke("consolidate-guides.xqy"),

(: Convert each title and chapter doc into renderable XML. :)
xdmp:invoke("convert-guides.xqy"),

xdmp:log("[setup-guides.xqy] done")

(: apidoc/setup-guides.xqy :)