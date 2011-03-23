xquery version "1.0-ml";

declare variable $toc := doc('/media/apiTOC/toc.xml');

(: Generate and insert a list page for each TOC container :)
xdmp:xslt-invoke("make-list-pages.xsl", $toc)/xdmp:document-insert(base-uri(.), .)
