xquery version "1.0-ml";

(: This module provides access to the raw database,
   which the setup scripts use to import content :)

module namespace raw = "http://marklogic.com/rundmc/raw-docs-access";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

declare variable $raw:db-name := string(u:get-doc("/apidoc/config/source-database.xml"));

declare variable $raw:common-import :=
                 'import module namespace api = "http://marklogic.com/rundmc/api" at "/apidoc/model/data-access.xqy";
                  declare namespace apidoc="http://marklogic.com/xdmp/apidoc";';

declare variable $raw:common-options := <options xmlns="xdmp:eval">
                                          <database>{xdmp:database($raw:db-name)}</database>
                                        </options>;

(: REST API docs, i.e. the "manage" lib, are represented the same as the XQuery API docs, but we're going to treat them differently. :)
declare variable $raw:func-docs  := raw:get-docs('xdmp:directory(concat("/",$api:version,"/apidoc/")) [apidoc:module[not(@lib eq "manage")]]');
declare variable $raw:rest-docs  := raw:get-docs('xdmp:directory(concat("/",$api:version,"/apidoc/")) [apidoc:module[    @lib eq "manage" ]]');

declare variable $raw:api-docs := ($raw:func-docs, $raw:rest-docs);

declare variable $raw:guide-docs := raw:get-docs('xdmp:directory(concat("/",$api:version,"/guide/"),"infinity")[*]');

declare function raw:get-docs($expr as xs:string) {
  let $query := concat($raw:common-import, $expr)
  return
    xdmp:eval($query, (), $raw:common-options)
};

declare function raw:get-doc($uri) {
  let $query := concat('doc("',$uri,'")')
  return 
    xdmp:eval($query, (), $raw:common-options)
};

(: Translate the URI of the raw, combined guide to the URI of the final target guide;
   store all the final guides in /apidoc :)
declare function raw:target-guide-doc-uri($guide as document-node()) {
  raw:target-guide-doc-uri-for-string(base-uri($guide))
};

declare function raw:target-guide-doc-uri-for-string($guide-uri as xs:string) {
  concat("/apidoc",$guide-uri)
};
