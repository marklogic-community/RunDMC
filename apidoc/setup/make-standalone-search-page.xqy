xquery version "1.0-ml";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

(: Generate and insert a list page for each TOC container :)
xdmp:log("Creating the standalone search page"),
xdmp:document-insert("/apidoc/do-search.xml",
  <ml:page xmlns:ml="http://developer.marklogic.com/site/internal" disable-comments="yes" status="Published" xmlns="http://www.w3.org/1999/xhtml">
    <h1>Search Results</h1>
    <ml:search-results/>
  </ml:page>
),
xdmp:log("Done."),

"Generated the standalone apidoc search page."
