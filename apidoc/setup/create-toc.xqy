xquery version "1.0-ml";

(: Create the new XML TOC :)

declare variable $toc-xml-url as xs:string external;

"Generating XML TOC...",
xdmp:document-insert($toc-xml-url,
                     xdmp:xslt-invoke("toc.xsl", document{ <empty/> }))
