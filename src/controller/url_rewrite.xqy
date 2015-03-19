xquery version "1.0-ml";
(: Main rewriter.
 :)

import module namespace rw="http://marklogic.com/rundmc/rewrite"
 at "/controller/rewrite.xqm";

rw:rewrite()

(: url_rewrite.xqy :)
