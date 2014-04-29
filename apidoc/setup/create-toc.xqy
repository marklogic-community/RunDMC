xquery version "1.0-ml";

(: Create the new XML TOC :)

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

$stp:helpXsdCheck,

xdmp:log(concat("Creating the new XML-based TOC at ",$stp:toc-xml-uri,"...")),

xdmp:document-insert($stp:toc-xml-uri,
                     xdmp:xslt-invoke("toc.xsl", document{ <empty/> })),

xdmp:log("Done."),
concat("Created the XML-based TOC at ",$stp:toc-xml-uri, " in ",
       xs:string(xdmp:elapsed-time()), ".")
