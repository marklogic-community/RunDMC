xquery version "1.0-ml";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

(: Make sure the version param was specified, particularly for the sake of render-toc.xqy below :)
$setup:errorCheck,

(: Extract the functions from the raw docs database and prepare for our use :)
xdmp:invoke("pull-function-docs.xqy"),

(: Create the XML TOC as a subsequent transaction, since it depends on the documents inserted above. :)
xdmp:invoke("create-toc.xqy"),

(: Create the HTML TOC based on the XML TOC we just created :)
xdmp:invoke("render-toc.xqy"),

(: Create list pages in a subsequent transaction, since they depend on both the inserted documents and the XML TOC :)
xdmp:invoke("make-list-pages.xqy"),

(: Make the search page :)
xdmp:invoke("make-search-page.xqy"),

(: Delete the old HTML TOCs, whatever they're named :)
(: UNTESTED; leave this out for now
xdmp:log(concat("Deleting the old HTML TOCs in ",$toc-dir,"...")),
let $old-tocs := (let $toc in xdmp:directory($toc-dir) order by $toc return $toc)
                 [position() ne last()]
  return
    $old-tocs/xdmp:document-delete(base-uri(.)),
:)


xdmp:log("All done!")
