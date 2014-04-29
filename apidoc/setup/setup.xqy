xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

(: Make sure the version and help-xsd-dir params were specified :)
$stp:errorCheck,
$stp:helpXsdCheck,

(
  (: Extract the functions from the raw docs database and prepare for our use :)
  "pull-function-docs.xqy",
  (: Create the XML TOC as a subsequent transaction,
   : since it depends on the documents inserted above.
   :)
  "create-toc.xqy",
  (: Create the HTML TOC based on the XML TOC we just created :)
  "render-toc.xqy",
  (: Clean up the old HTML TOC(s) :)
  "delete-old-toc.xqy",
  (: Create list pages in a subsequent transaction,
   : since they depend on both the inserted documents and the XML TOC.
   :)
  "make-list-pages.xqy")
! xdmp:invoke(.)
,

xdmp:log("[apidoc/setup.xqy] done")

(: apidoc/setup.xqy :)
