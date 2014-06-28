xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

stp:list-pages-render(),

text { "Generated all function list pages", xdmp:elapsed-time() }

(: make-list-pages.xqy :)