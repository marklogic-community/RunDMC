xquery version "1.0-ml";

(: This module provides access to the raw database,
   which the setup scripts use to import content :)

module namespace raw = "http://marklogic.com/rundmc/raw-docs-access";

import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

declare variable $raw:db-name := fn:string(u:get-doc("/apidoc/config/source-database.xml"));

declare variable $raw:api-docs :=
  let $query := 'import module namespace api = "http://marklogic.com/rundmc/api" at "/apidoc/model/data-access.xqy";
                 declare namespace apidoc="http://marklogic.com/xdmp/apidoc";
                 xdmp:directory(fn:concat("/",$api:version,"/apidoc/")) [apidoc:module]
                '
  return
    xdmp:eval($query, (), <options xmlns="xdmp:eval">
                            <database>{xdmp:database($raw:db-name)}</database>
                          </options>);

declare variable $raw:guide-docs :=
  let $query := 'import module namespace api = "http://marklogic.com/rundmc/api" at "/apidoc/model/data-access.xqy";
                 declare namespace apidoc="http://marklogic.com/xdmp/apidoc";
                 xdmp:directory(fn:concat("/",$api:version,"/guides/"))
                '
  return
    xdmp:eval($query, (), <options xmlns="xdmp:eval">
                            <database>{xdmp:database($raw:db-name)}</database>
                          </options>);

