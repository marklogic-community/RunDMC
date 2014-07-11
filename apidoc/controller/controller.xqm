xquery version "1.0-ml";
(: Controller code for apidoc requests. :)

module namespace c="http://marklogic.com/rundmc/api/controller" ;

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;

declare function c:http-request-version()
as xs:string?
{
  xdmp:get-request-field("version")
};

declare function c:version(
  $request-version as xs:string?)
as xs:string
{
  if ($request-version) then $request-version
  else $api:DEFAULT-VERSION
};

declare function c:version()
as xs:string
{
  c:version(c:http-request-version())
};

(: apidoc/controller/controller.xqm :)