xquery version "1.0-ml";

module namespace setup = "http://marklogic.com/rundmc/api/setup";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

declare variable $setup:toc-dir     := concat("/media/apiTOC/",$api:version,"/");
declare variable $setup:toc-xml-url := concat($toc-dir,"toc.xml");
declare variable $setup:toc-url     := concat($toc-dir,"apiTOC_", current-dateTime(), ".html");

declare variable $setup:toc-default-dir         := concat("/media/apiTOC/default/");
declare variable $setup:toc-url-default-version := concat($toc-default-dir,"apiTOC_", current-dateTime(), ".html");

declare variable $setup:processing-default-version := $api:version eq $api:default-version;

declare variable $setup:errorCheck := if (not($api:version-specified)) then error(xs:QName("ERROR"), "You must specify a 'version' param.") else ();

declare variable $setup:helpXsdCheck := if (not(xdmp:get-request-field("help-xsd-dir"))) then error(xs:QName("ERROR"), "You must specify a 'help-xsd-dir' param.") else (); (: used in create-toc.xqy / toc-help.xsl :)

(: look at document-list.xml to change url names based on that list :)
declare function setup:fix-guide-names($s as xs:string, $num as xs:integer) {

let $x := xdmp:document-get(concat(xdmp:modules-root(), 
              "/apidoc/config/document-list.xml"))
let $source := $x//guide[@url-name ne @source-name]/@source-name/string()
let $url := $x//guide[@url-name ne @source-name]/@url-name/string()
let $count := count($source)
return
if ($num eq $count + 1)
then (xdmp:set($num, 9999), $s)
else if ($num eq 9999) 
     then $s 
     else setup:fix-guide-names(replace($s, $source[$num], $url[$num]), 
             $num + 1)

};

