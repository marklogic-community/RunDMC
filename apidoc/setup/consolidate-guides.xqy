xquery version "1.0-ml";

(: This script is run in the raw database, setting up the URLs for the XML
 : files for each guide, and adding a chapter list to the title doc.
 :)

import module namespace guide="http://marklogic.com/rundmc/api/guide"
  at "guide.xqm" ;

declare variable $VERSION as xs:string external ;

guide:consolidate($VERSION)

(: apidoc/setup/consolidate-guides.xqy :)