xquery version "1.0-ml";


(: Extract the functions from the "docapp" database and prepare for our use :)
xdmp:log("Pulling function docs from the docapp database..."),
xdmp:invoke("pull-function-docs.xqy"),
xdmp:log("Done.")

;
declare variable $toc-dir     := "/media/apiTOC/";

(: Delete the old HTML TOC, whatever it's named :)
xdmp:log(concat("Deleting the old HTML TOC dir (",$toc-dir,"...")),
xdmp:directory-delete($toc-dir),
xdmp:log("Done.")

;
declare variable $toc-dir     := "/media/apiTOC/";
declare variable $toc-xml-url := concat($toc-dir,"toc.xml");

(: Create the XML TOC as a subsequent transaction, since it depends on the documents inserted above. :)
xdmp:log(concat("Creating the new XML-based TOC at ",$toc-xml-url,"...")),
xdmp:invoke("create-toc.xqy", (xs:QName("toc-xml-url"), $toc-xml-url)),
xdmp:log("Done.")

;
declare variable $toc-dir     := "/media/apiTOC/";
declare variable $toc-xml-url := concat($toc-dir,"toc.xml");
declare variable $toc-url     := concat($toc-dir,"apiTOC_", current-dateTime(), ".html");

(: Create the HTML TOC based on the XML TOC we just created :)
xdmp:log(concat("Rendering the XML-based TOC to HTML at ",$toc-url,"...")),
xdmp:invoke("render-toc.xqy", (xs:QName("toc-url"), $toc-url,
                               xs:QName("toc-xml-url"), $toc-xml-url)),
xdmp:log("Done.")

;
declare variable $toc-dir     := "/media/apiTOC/";
declare variable $toc-xml-url := concat($toc-dir,"toc.xml");

(: Create list pages in a subsequent transaction, since they depend on both the inserted documents and the XML TOC :)
xdmp:log("Creating the list pages, based on data in docapp and the XML TOC..."),
xdmp:invoke("make-list-pages.xqy", (xs:QName("toc-xml-url"), $toc-xml-url)),
xdmp:log("Done.")

;
declare variable $toc-dir     := "/media/apiTOC/";
declare variable $toc-xml-url := concat($toc-dir,"toc.xml");

(: Delete the XML TOC; we're done using it :)
xdmp:log("Deleting the XML TOC; we're done using it..."),
xdmp:document-delete($toc-xml-url),
xdmp:log("All done!")
