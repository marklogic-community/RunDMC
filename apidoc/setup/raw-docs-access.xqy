xquery version "1.0-ml";

(: This module provides access to the docapp database,
   which the setup scripts use to import content :)

module namespace docapp = "http://marklogic.com/rundmc/docapp-data-access";

import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

declare variable $docapp:docs :=
  let $query := 'import module namespace api = "http://marklogic.com/rundmc/api" at "/apidoc/model/data-access.xqy";
                 declare namespace apidoc="http://marklogic.com/xdmp/apidoc";
                 xdmp:directory(fn:concat("http://pubs/",$api:version,"doc/apidoc/"),"infinity") [apidoc:module]
                '
  return
    xdmp:eval($query, (), <options xmlns="xdmp:eval">
                            <database>{xdmp:database("docapp")}</database>
                          </options>);
