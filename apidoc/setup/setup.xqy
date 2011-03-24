xquery version "1.0-ml";

declare variable $toc-dir     := "/media/apiTOC/";
declare variable $toc-xml-url := concat($toc-dir,"toc.xml");
declare variable $toc-url     := concat($toc-dir,"apiTOC_", current-dateTime(), ".html");

(: Extract the functions from the "docapp" database and prepare for our use :)
xdmp:invoke("pull-function-docs.xqy"),

(: Delete the old HTML TOC, whatever it's named :)
xdmp:directory-delete($toc-dir),

(: Create the XML TOC as a subsequent transaction, since it depends on the documents inserted above. :)
xdmp:invoke("create-toc.xqy", (xs:QName("toc-xml-url"), $toc-xml-url)),

(: Create the HTML TOC based on the XML TOC we just created :)
xdmp:invoke("render-toc.xqy", (xs:QName("toc-url"), $toc-url,
                               xs:QName("toc-xml-url"), $toc-xml-url)),

(: Create list pages in a subsequent transaction, since they depend on both the inserted documents and the XML TOC :)
xdmp:invoke("make-list-pages.xqy", (xs:QName("toc-xml-url"), $toc-xml-url)),

(: Delete the XML TOC; we're done using it :)
xdmp:document-delete($toc-xml-url)
