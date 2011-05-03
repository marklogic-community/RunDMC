xquery version "1.0-ml";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

(: Generate and insert a list page for each TOC container :)
xdmp:log("Creating the list pages, based on data in docapp and the XML TOC..."),
xdmp:xslt-invoke("make-list-pages.xsl", doc($setup:toc-xml-url))/xdmp:document-insert(base-uri(.), .),
xdmp:log("Done."),

"Generated all function list pages, etc."
