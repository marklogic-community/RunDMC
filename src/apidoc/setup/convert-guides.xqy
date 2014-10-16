xquery version "1.0-ml";

import module namespace guide="http://marklogic.com/rundmc/api/guide"
  at "/apidoc/setup/guide.xqm" ;
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "/apidoc/setup/raw-docs-access.xqy" ;

declare variable $VERSION as xs:string external ;

guide:render(raw:guide-docs($VERSION))

(: convert-guides.xqy :)