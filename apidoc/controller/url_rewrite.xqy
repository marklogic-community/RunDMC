xquery version "1.0-ml";
(: URL rewriter.
 : This is a thin wrapper around the rewrite.xqm library.
 :)
import module namespace rw="http://marklogic.com/rundmc/apidoc/rewrite"
  at "/apidoc/controller/rewrite.xqm";

rw:rewrite()

(: url_rewrite.xqy :)
