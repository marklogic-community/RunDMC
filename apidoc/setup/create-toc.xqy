xquery version "1.0-ml";

(: Create the new XML TOC :)

import module namespace setup="http://marklogic.com/rundmc/api/setup"
  at "common.xqy";

$setup:helpXsdCheck,

xdmp:log(concat("Creating the new XML-based TOC at ",$setup:toc-xml-url,"...")),

xdmp:document-insert($setup:toc-xml-url,
                     xdmp:xslt-invoke("toc.xsl", document{ <empty/> })),

xdmp:log("Done."),
concat("Created the XML-based TOC at ",$setup:toc-xml-url, " in ",
       xs:string(xdmp:elapsed-time()), ".")
