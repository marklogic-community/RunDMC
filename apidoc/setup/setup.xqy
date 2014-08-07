xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $VERSION as xs:string external ;

declare variable $HELP-XSD-DIR as xs:string external ;

declare variable $VARS := (
  xs:QName('HELP-XSD-DIR'), $HELP-XSD-DIR,
  xs:QName('VERSION'), $VERSION) ;

(
  (: Extract the functions from the raw docs database and prepare for our use :)
  "pull-function-docs.xqy",

  (: Create the XML TOC as a subsequent transaction,
   : since it depends on the documents inserted above.
   :)
  "create-toc.xqy",

  (: Create the HTML TOC based on the XML TOC we just created :)
  "render-toc.xqy",

  (: Create list pages in a subsequent transaction,
   : since they depend on both the inserted documents and the XML TOC.
   :)
  "make-list-pages.xqy")
! xdmp:invoke(., $VARS)
,

stp:info("apidoc/setup.xqy", (xdmp:elapsed-time()))

(: apidoc/setup.xqy :)
