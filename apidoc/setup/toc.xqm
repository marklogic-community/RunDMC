xquery version "1.0-ml";
(: TOC setup functions. :)

module namespace toc="http://marklogic.com/rundmc/api/toc" ;

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;
import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";

declare namespace xhtml="http://www.w3.org/1999/xhtml" ;

(: We look back into the raw docs database
 : to get the introductory content for each function list page.
 :)
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "/apidoc/setup/raw-docs-access.xqy" ;

declare namespace apidoc="http://marklogic.com/xdmp/apidoc" ;

declare variable $ALL-FUNCTIONS := (
  $api:all-function-docs/api:function-page/api:function[1]) ;

declare variable $ALL-FUNCTIONS-JAVASCRIPT := (
  $api:ALL-FUNCTIONS-JAVASCRIPT/api:javascript-function-page/api:function[1]) ;

(: exclude REST API "functions"
 : dedup when there is a built-in lib that has the same prefix as a library
 : lib - can probably do this more efficiently
 :)
declare variable $ALL-LIBS as element(api:lib)* := (
  $api:built-in-libs,
  $api:library-libs[not(. eq 'REST')][not(. = $api:built-in-libs)]) ;

declare variable $ALL-LIBS-JAVASCRIPT as element(api:lib)* := (
  $api:LIBS-JAVASCRIPT );

(: This is for specifying exceptions to the automated mappings
 : of categories to URLs.
 :)
declare variable $CATEGORY-MAPPINGS := (
  u:get-doc('/apidoc/config/category-mappings.xml')/*/category) ;

declare variable $GUIDE-DOCS := xdmp:directory(
  concat($api:VERSION-DIR, 'guide/'))[guide] ;

declare variable $GUIDE-GROUPS := u:get-doc(
  '/apidoc/config/document-list.xml')/docs/group[guide] ;

declare variable $GUIDE-DOCS-NOT-CONFIGURED := (
  $GUIDE-DOCS except toc:guides-in-group($GUIDE-GROUPS)) ;

declare function toc:display-category($cat as xs:string)
as xs:string
{
  if (ends-with($cat,'Builtins')) then substring-before($cat,'Builtins')
  else $cat
};

declare function toc:path-for-category(
  $cat as xs:string)
as xs:string
{
  let $explicitly-specified := $CATEGORY-MAPPINGS[@from eq $cat]/@to
  return (
    if ($explicitly-specified) then $explicitly-specified
    else translate(lower-case(toc:display-category($cat)), ' ', '-'))
};

declare function toc:category-page-title(
  $cat as xs:string,
  $lib as xs:string?,
  $secondary-lib as xs:string?)
as element()
{
  <title xmlns="">
  {
    element a {
      attribute href { "/"||$lib },
      api:prefix-for-lib($lib) },
    ' functions ('||toc:display-category($cat)||')',
    if (not($secondary-lib)) then () else (
      'and',
      element a {
        attribute href { "/"||$secondary-lib },
        api:prefix-for-lib($secondary-lib) },
      'functions')
  }
  </title>
};

declare function toc:REST-page-title(
  $category as xs:string,
  $subcategory as xs:string?)
as element()
{
  <title xmlns="">
  {
    $category,
    if (not($subcategory)) then () else (
      ' ('||$subcategory||')')
  }
  </title>
};

declare function toc:function-name-nodes(
  $functions as element(api:function)*)
as element(api:function-name)*
{
  (: NOTE: These elements are intentionally siblings (not parentless),
   : so the TOC construction code has the option of
   : inspecting their siblings.
   :)
  let $wrapper := element api:wrapper {
    for $f in $functions
    let $is-javascript := xs:boolean($f/@is-javascript)
    (: By default, just use alphabetical order.
     : But for REST docs, first sort by the resource name
     : and then the HTTP method.
     :)
    let $not-rest := not($f/@lib eq 'REST')
    order by
      if ($not-rest) then $f/@fullname
      else api:name-from-REST-fullname($f/@fullname),
      if ($not-rest) then ()
      else api:verb-sort-key-from-REST-fullname($f/@fullname)
    return element api:function-name {
      if ($not-rest) then ()
      else attribute is-REST { not($not-rest) },
      if (not($is-javascript)) then ()
      else attribute is-javascript { $is-javascript },
      $f/@fullname/string() } }
  (: TODO why exclude 'sem:'? :)
  return $wrapper/api:function-name[. ne 'sem:']
};

(: Returns the one library string if all the functions are in the same library.
 : Otherwise returns empty.
 :)
declare function toc:lib-for-all(
  $functions as element()*)
as xs:string?
{
  let $libs := distinct-values($functions/@lib)
  (: This is a hack to make the semantics library work.
   : It has multiple namespace.
   :)
  return (
    if (count($libs) eq 1) then ($functions/@lib)[1]
    else if (($functions/@category)[1] eq 'Semantics') then 'sem'
    else ())
};

(: Uses toc:lib-for-most (because I already implemented it)
 : but favors "xdmp" as primary regardless :)
declare function toc:primary-lib($functions as element()*)
  as xs:string
{
  if ($functions/@lib = 'xdmp') then 'xdmp'
  else toc:lib-for-most($functions)
};

(: Returns the most common library string among the given functions
 : Handles the unique "XSLT" and "JSON" subcategories,
 : which each represent more than one library.
 :)
declare function toc:lib-for-most($functions as element()*)
  as xs:string
{
  (
    for $name in distinct-values($functions/@lib)
    let $count := count($functions[@lib eq $name])
    order by $count descending
    return $name)[1]
};

declare function toc:category-is-exhaustive(
  $category as xs:string,
  $sub-category as xs:string?,
  $lib-for-all as xs:string?)
as xs:boolean
{
  $lib-for-all and (
    let $num-functions-in-lib := count($ALL-FUNCTIONS[@lib eq $lib-for-all])
    let $num-functions-in-category := count(
      $ALL-FUNCTIONS[@category eq $category]
      [not($sub-category) or @subcategory eq $sub-category])
    return $num-functions-in-lib eq $num-functions-in-category)
};

declare function toc:display-suffix($lib-for-all as xs:string?)
  as xs:string?
{
  (: Don't display a suffix for REST categories :)
  if ($lib-for-all eq 'REST') then ()
  else if ($lib-for-all) then concat(
    ' (', api:prefix-for-lib($lib-for-all), ':)')
  else ()
};

declare function toc:get-summary-for-category(
  $cat as xs:string,
  $subcat as xs:string?,
  $lib as xs:string?)
  as element(apidoc:summary)*
{
  let $summaries-with-category := $raw:API-DOCS/apidoc:module/apidoc:summary[
    @category eq $cat][not($subcat) or @subcategory eq $subcat]
  return (
    if ($summaries-with-category) then $summaries-with-category
    else (
      let $modules-with-category := $raw:API-DOCS/apidoc:module[
        @category eq $cat][not($subcat) or @subcategory eq $subcat]
      return (
        if ($modules-with-category/apidoc:summary)
        then $modules-with-category/apidoc:summary
        else (
          (: Fallback boilerplate is different for library modules
           : than for built-ins.
           :
           : The admin library sub-pages don't have their own descriptions.
           : So use this boilerplate instead
           :)
          if ($lib = $ALL-LIBS[not(@built-in)]) then element apidoc:summary {
            <p>
            For information on how to import the functions in this module,
            refer to the main
            <a href="/{$lib}">{ api:prefix-for-lib($lib) } library page</a>.
            </p> }

          (: ASSUMPTION Only REST sub-categories may need this fallback
           : all main categories (e.g., Client API and Management API)
           : already have summaries written
           :)
          else if ($lib eq 'REST') then element apidoc:summary {
            <p>
            For the complete list of REST resources in this category,
            refer to the main <a href="/REST/{toc:path-for-category($cat)}">{
              toc:display-category($cat) } page</a>.
            </p> }

          (: some of the xdmp sub-pages don't have descriptions either,
           : so use this
           :)
          else element apidoc:summary {
            <p>
            For the complete list of functions and categories in this namespace,
            refer to the main <a href="/{$lib}">{
              api:prefix-for-lib($lib) } functions page</a>.
            </p> }))))
};

(: We only want to see one summary :)
declare function toc:get-summary-for-lib($lib as xs:string)
  as element()?
{
  (: exceptional ("json" built-in) :)
  let $lib-subcat := toc:hard-coded-subcategory($lib)
  let $summaries-by-summary-subcat := $raw:API-DOCS/apidoc:module/apidoc:summary[
    @subcategory eq $lib-subcat]
  (: exceptional ("spell" built-in) :)
  let $lib-cat := toc:hard-coded-category($lib)
  let $summaries-by-module-cat := $raw:API-DOCS/apidoc:module[
    @category eq $lib-cat]/apidoc:summary
  (: the most common case :)
  let $lib-prefix := api:prefix-for-lib($lib)
  let $summaries-by-module-lib := $raw:API-DOCS/apidoc:module[
    @lib eq $lib-prefix]/apidoc:summary
  (: exceptional ("map") :)
  let $summaries-by-summary-lib := $raw:API-DOCS/apidoc:module/apidoc:summary[
    @lib eq $lib-prefix]
  (: exceptional ("dls") :)
  let $summaries-by-module-lib-no-subcat := $summaries-by-module-lib[
    not(@subcategory)]
  return (
    if (count($summaries-by-summary-subcat) eq 1) then $summaries-by-summary-subcat
    else if (count($summaries-by-module-lib) eq 1) then $summaries-by-module-lib
    else if (count($summaries-by-summary-lib) eq 1) then $summaries-by-summary-lib
    else if (count($summaries-by-module-lib-no-subcat) eq 1) then $summaries-by-module-lib-no-subcat
    else ())
};

(: Look in the  namespaces/libs config file
 : to see if we've forced a hard-coded category
 : for summary-lookup purposes.
 :)
declare function toc:hard-coded-category($lib as xs:string)
  as xs:string?
{
  $api:namespace-mappings[@lib eq $lib]/@category
};

(: Look in the  namespaces/libs config file
 : to see if we've forced a hard-coded subcategory
 : for summary-lookup purposes.
 :)
declare function toc:hard-coded-subcategory($lib as xs:string)
  as xs:string?
{
  $api:namespace-mappings[@lib eq $lib]/@subcategory
};

declare function toc:guides-in-group($groups as element(group)*)
as document-node()*
{
  doc(
    $groups/guide/concat(
      $api:VERSION-DIR, 'guide/', @url-name, '.xml'))
};

(: Build a TOC href with fragment for this guide section.
 :)
declare function toc:guide-href(
  $e as element(xhtml:div))
as xs:string
{
  concat(
    api:external-uri($e),
    '#',
    ($e/*[1] treat as element(xhtml:a))/@id)
};

(: Database URI for a rendered async TOC section. :)
declare function toc:uri(
  $parent as xs:string,
  $id as xs:string,
  $mode as xs:string?)
as xs:string
{
  concat(
    $parent,
    switch($mode)
    case 'javascript' return 'js/'
    default return '',
    $id,
    '.html')
};

(: Rewrite rendered node id as needed for javascript.
 : For the toc_filter javascript this needs to be a valid xs:ID,
 : so we use 'js_' instead of 'js/'.
 :)
declare function toc:node-id(
  $node as element(node))
as xs:ID
{
  xs:ID(
    concat(
      if (xs:boolean($node/@is-javascript)
        or $node/@type = 'javascript-function') then 'js_'
      else '',
      $node/@id))
};

(: apidoc/setup/toc.xqm :)