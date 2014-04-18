xquery version "1.0-ml";

(: This module provides access to the raw database,
   which the setup scripts use to import content :)

module namespace raw="http://marklogic.com/rundmc/raw-docs-access";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";

import module namespace api = "http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";

declare variable $DATABASE := xdmp:database(
  u:get-doc("/apidoc/config/source-database.xml")) ;

declare variable $OPTIONS := (
  <options xmlns="xdmp:eval">
  {
    element database { $DATABASE }
  }
  </options>) ;

declare variable $OPTIONS-UPDATE := (
  <options xmlns="xdmp:eval">
  {
    element database { $DATABASE },
    element transaction-mode { 'update' }
  }
  </options>) ;

(: REST API docs, i.e. the "manage" lib,
 : are represented the same as the XQuery API docs,
 : but we're going to treat them differently.
 :)
declare variable $API-DOCS := raw:invoke-function(
  function() {
    xdmp:directory(
      concat("/", $api:version, "/apidoc/"))[apidoc:module] });

declare variable $GUIDE-DOCS := raw:invoke-function(
  function() {
    xdmp:directory(
      concat("/", $api:version, "/guide/"), "infinity")[*] }) ;

(: Shortcut for xdmp:invoke-function. :)
declare function raw:invoke-function(
  $fn as xdmp:function,
  $update as xs:boolean?)
as item()*
{
  xdmp:invoke-function(
    $fn,
    if (not($update)) then $OPTIONS
    else $OPTIONS-UPDATE)
};

declare function raw:invoke-function(
  $fn as xdmp:function)
as item()*
{
  raw:invoke-function($fn, ())
};

(: Shortcut for xdmp:invoke. :)
declare function raw:invoke(
  $uri as xs:string,
  $vars as item()*)
as item()*
{
  xdmp:invoke($uri, $vars, $OPTIONS)
};

(: Shortcut for xdmp:invoke. :)
declare function raw:invoke(
  $uri as xs:string)
as item()*
{
  raw:invoke($uri, ())
};

declare function raw:get-doc($uri as xs:string)
as document-node()?
{
  raw:invoke-function(function() { doc($uri) })
};

declare function raw:target-guide-doc-uri-for-string(
  $guide-uri as xs:string)
as xs:string
{
  concat("/apidoc", $guide-uri)
};

(: Translate the URI of the raw, combined guide
 : to the URI of the final target guide;
 : store all the final guides in /apidoc
 :)
declare function raw:target-guide-doc-uri(
  $guide as document-node())
as xs:string
{
  raw:target-guide-doc-uri-for-string(base-uri($guide))
};

(: apidoc/setup/raw-docs-access.xqy :)