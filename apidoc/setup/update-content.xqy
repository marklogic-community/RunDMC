xquery version "1.0-ml";

(: Extract the functions from the "docapp" database and prepare for our use :)
xdmp:invoke("pull-function-docs.xqy"),

(: Create the TOC as a subsequent transaction, since it depends on the documents inserted above. :)
xdmp:invoke("update-toc.xqy"),

(: Create list pages in a subsequent transaction, since they depend on both the documents and the TOC :)
xdmp:invoke("make-list-pages.xqy")
