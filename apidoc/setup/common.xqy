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
