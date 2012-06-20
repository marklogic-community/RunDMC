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

(: Clean up the old HTML TOC(s) :)
xdmp:invoke("delete-old-toc.xqy"),

(: Create list pages in a subsequent transaction, since they depend on both the inserted documents and the XML TOC :)
xdmp:invoke("make-list-pages.xqy"),

xdmp:log("All done!")
