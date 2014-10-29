xquery version "1.0-ml";

import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy" ;
import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;
import module namespace guide="http://marklogic.com/rundmc/api/guide"
  at "guide.xqm" ;

(: This may be invoked on the task server,
 : where get-request-field will not find the right version.
 :)
declare variable $VERSION as xs:string external ;

guide:images($VERSION)
, "Done copying guide images."

(: copy-guide-images.xqy :)