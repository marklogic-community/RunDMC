xquery version "1.0-ml";
(: Main rewriter.
 : TODO move this code into the library module.
 :)

import module namespace rw="http://marklogic.com/rundmc/rewrite"
 at "/controller/rewrite.xqm";

rw:rewrite()

(: url_rewrite.xqy :)

