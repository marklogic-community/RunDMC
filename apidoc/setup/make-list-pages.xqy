xquery version "1.0-ml";

declare variable $toc-xml-url as xs:string external;

(: Generate and insert a list page for each TOC container :)
xdmp:xslt-invoke("make-list-pages.xsl", doc($toc-xml-url))/xdmp:document-insert(base-uri(.), .)
