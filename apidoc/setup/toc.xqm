xquery version "1.0-ml";
(: TOC setup functions. :)

module namespace toc="http://marklogic.com/rundmc/api/toc" ;

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml" ;

(: We look back into the raw docs database
 : to get the introductory content for each function list page.
 :)
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "/apidoc/setup/raw-docs-access.xqy" ;

(: The help page code relies on undocumented and unsupported functions
 : found in the MarkLogic admin UI code.
 :)
import module namespace af="http://marklogic.com/xdmp/admin/admin-forms"
  at "/MarkLogic/admin/admin-forms.xqy" ;

declare namespace apidoc="http://marklogic.com/xdmp/apidoc" ;

(: exclude REST API "functions"
 : dedup when there is a built-in lib that has the same prefix as a library
 : lib - can probably do this more efficiently
 :)
declare variable $ALL-LIBS as element(api:lib)* := (
  $api:built-in-libs,
  $api:library-libs[not(. eq $api:MODE-REST)][not(. = $api:built-in-libs)]) ;

declare variable $ALL-LIBS-JAVASCRIPT as element(api:lib)* := (
  $api:LIBS-JAVASCRIPT );

(: This is for specifying exceptions to the automated mappings
 : of categories to URIs.
 :)
declare variable $CATEGORY-MAPPINGS := u:get-doc(
  '/apidoc/config/category-mappings.xml')/*/category ;

declare variable $GUIDE-DOCS := xdmp:directory(
  concat(api:version-dir($api:version), 'guide/'))[guide] ;

declare variable $GUIDE-GROUPS as element(group)+ := (
  $api:DOCUMENT-LIST/group[guide]) ;

declare variable $GUIDE-DOCS-NOT-CONFIGURED := (
  $GUIDE-DOCS except toc:guides-in-group($GUIDE-GROUPS)) ;

declare variable $HELP-ROOT-HREF := '/admin-help' ;

declare variable $MAP-KEY-BUCKET := 'BUCKET' ;
declare variable $MAP-KEY-CATSUBCAT := 'CATSUBCAT' ;
declare variable $MAP-KEY-LIB := 'LIBRARY' ;

(: Prestructured map by mode,
 : containing maps by bucket, category+subcategory, and lib.
 : This allows easy access to all the grouping info
 : after one pass through the function sequence.
 :)
declare function toc:functions-map($version as xs:string)
as map:map
{
  let $m := map:map()
  let $_ := (
    for $mode in $api:MODES
    let $_ := map:put(
      $m, $mode,
      map:new(
        (map:entry($MAP-KEY-BUCKET, map:map()),
          map:entry($MAP-KEY-CATSUBCAT, map:map()),
          map:entry($MAP-KEY-LIB, map:map()))))
    return ())
  let $_ := (
    for $f in api:functions($version)
    let $fp := $f/api:function-page
    let $f1 := $fp/api:function[1]
    let $mode as xs:string := $fp/@mode
    let $m-mode := map:get($m, $mode)
    let $bucket as xs:string := $f1/@bucket
    let $cat as xs:string := $f1/@category
    let $subcat as xs:string? := $f1/@subcategory
    let $catsubcat as xs:string := $cat||'#'||$subcat
    let $lib as xs:string := $f1/@lib
    let $m-bucket := map:get($m-mode, $MAP-KEY-BUCKET)
    let $m-catsubcat := map:get($m-mode, $MAP-KEY-CATSUBCAT)
    let $m-lib := map:get($m-mode, $MAP-KEY-LIB)
    let $m-cat := map:get($m-bucket, $bucket)
    let $_ := (
      if (exists($m-cat)) then map:put(
        $m-cat, $cat, (map:get($m-cat, $cat), $f1))
      else map:put(
        $m-bucket, $bucket, map:new(map:entry($cat, $f1))))
    let $_ := map:put(
      $m-catsubcat, $catsubcat, (map:get($m-catsubcat, $catsubcat), $f1))
    let $_ := map:put(
      $m-lib, $lib, (map:get($m-lib, $lib), $f1))
    return ())
  return $m
} ;

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
  element toc:title {
    (: Children will be in the default element namespace,
     : which is empty.
     :)
    element a {
      attribute href { "/"||$lib },
      api:prefix-for-lib($lib) },
    ' functions ('||toc:display-category($cat)||')',
    if (not($secondary-lib)) then () else (
      'and',
      element a {
        attribute href { "/"||$secondary-lib },
        api:prefix-for-lib($secondary-lib) },
      'functions') }
};

declare function toc:REST-page-title(
  $category as xs:string,
  $subcategory as xs:string?)
as element()
{
  element toc:title {
    (: Children will be in the default element namespace,
     : which is empty.
     :)
    $category,
    if (not($subcategory)) then () else (
      ' ('||$subcategory||')') }
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
  (for $name in distinct-values($functions/@lib)
    let $count := count($functions[@lib eq $name])
    order by $count descending
    return $name)[1]
};

declare function toc:category-is-exhaustive(
  $m-mode-functions as map:map,
  $category as xs:string,
  $subcategory as xs:string?,
  $lib as xs:string?)
as xs:boolean
{
  $lib and (
    let $m-lib as map:map := map:get(
      $m-mode-functions, $MAP-KEY-LIB)
    let $m-catsubcat as map:map := map:get(
      $m-mode-functions, $MAP-KEY-CATSUBCAT)
    let $num-functions-in-lib := count(
      map:get($m-lib, $lib))
    let $num-functions-in-category := count(
      map:get($m-catsubcat, $category||'#'||$subcategory))
    return $num-functions-in-lib eq $num-functions-in-category)
};

declare function toc:display-suffix($lib as xs:string?)
  as xs:string?
{
  (: Don't display a suffix for REST categories :)
  if (not($lib) or $lib eq $api:MODE-REST) then ()
  else concat(' (', api:prefix-for-lib($lib), ':)')
};

(: TODO refactor with version, so Task Server can do this. :)
(: TODO refactor to read directly from zip. :)
declare function toc:modules-raw()
as element(apidoc:module)+
{
  $raw:API-DOCS/apidoc:module
};

declare function toc:get-summary-for-category(
  $mode as xs:string,
  $cat as xs:string,
  $subcat as xs:string?,
  $lib as xs:string?)
  as element(apidoc:summary)*
{
  let $raw-modules as element()+ := toc:modules-raw()
  let $summaries-with-category := $raw-modules/apidoc:summary[
    @category eq $cat][not($subcat) or @subcategory eq $subcat]
  return (
    if ($summaries-with-category) then $summaries-with-category
    else (
      let $modules-with-category := $raw-modules[
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
            <a href="{
            concat(
            switch($mode)
            case $api:MODE-JAVASCRIPT return 'js/'
            default return '',
            $lib)
            }">{ api:prefix-for-lib($lib) } library page</a>.
            </p> }

          (: ASSUMPTION Only REST sub-categories may need this fallback
           : all main categories (e.g., Client API and Management API)
           : already have summaries written
           :)
          else if ($lib eq $api:MODE-REST) then element apidoc:summary {
            <p>
            For the complete list of REST resources in this category,
            refer to the main <a href="/REST/{toc:path-for-category($cat)}">{
              toc:display-category($cat) } page</a>.
            </p> }

          (: Some of the xdmp sub-pages don't have descriptions either,
           : so use this.
           :)
          else element apidoc:summary {
            <p>
            For the complete list of functions and categories in this namespace,
            refer to the main <a href="{
            concat(
            switch($mode)
            case $api:MODE-JAVASCRIPT return 'js/'
            default return '',
            $lib)
            }">{ api:prefix-for-lib($lib) }
            functions page</a>.
            </p> }))))
};

(: We only want to see one summary :)
declare function toc:get-summary-for-lib($lib as xs:string)
  as element()?
{
  let $raw-modules as element()+ := toc:modules-raw()
  (: exceptional ("json" built-in) :)
  let $lib-subcat as xs:string? := api:namespace($lib)/@subcategory
  let $summaries-by-summary-subcat := $raw-modules/apidoc:summary[
    @subcategory eq $lib-subcat]
  (: exceptional ("spell" built-in) :)
  let $lib-cat as xs:string? := api:namespace($lib)/@category
  let $summaries-by-module-cat := $raw-modules[
    @category eq $lib-cat]/apidoc:summary
  (: the most common case :)
  let $lib-prefix := api:prefix-for-lib($lib)
  let $summaries-by-module-lib := $raw-modules[
    @lib eq $lib-prefix]/apidoc:summary
  (: exceptional ("map") :)
  let $summaries-by-summary-lib := $raw-modules/apidoc:summary[
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

declare function toc:guides-in-group($groups as element(group)*)
as document-node()*
{
  doc(
    $groups/guide/concat(
      api:version-dir($api:version), 'guide/', @url-name, '.xml'))
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

declare function toc:id($n as node())
as xs:string
{
  generate-id($n)
};

declare function toc:id()
as xs:string
{
  toc:id(text { xdmp:random() })
};

declare function toc:node(
  $id as xs:string,
  $display as xs:string,
  $href as xs:string?,
  $is-async as xs:boolean?,
  $type as xs:string?,
  $extra-boolean-attributes as xs:string*,
  $body as item()*)
as element(toc:node)
{
  (: TODO validate structure? :)
  element toc:node {
    attribute id { $id },
    attribute display { $display },
    $href ! attribute href { . },
    $is-async ! attribute async { . },
    $type ! attribute type { . },
    $extra-boolean-attributes ! attribute { . } { true() },
    $body }
};

declare function toc:node(
  $id as xs:string,
  $display as xs:string,
  $href as xs:string?,
  $body as item()*)
as element(toc:node)
{
  toc:node($id, $display, $href, (), (), (), $body)
};

declare function toc:node(
  $id as xs:string,
  $display as xs:string,
  $body as item()*)
as element(toc:node)
{
  toc:node($id, $display, (), (), (), (), $body)
};

declare function toc:guide($n as node())
as node()?
{
  typeswitch($n)
  (: TODO why copy this text at all? :)
  case text() return $n
  case element(xhtml:div) return (
    if (not($n/@class = 'section')) then $n
    else toc:node(
      toc:id($n),
      (: ASSUMPTION Second element is a heading. :)
      $n/*[2],
      toc:guide-href($n),
      toc:guide($n/node())))
  default return ()
};

declare function toc:guide-node(
  $root as document-node(),
  $is-duplicate as xs:boolean)
as element(toc:node)
{
  toc:node(
    toc:id($root),
    ($root/guide treat as element())/title,
    api:external-uri($root),
    true(),
    'guide',
    ('sub-control', 'wrap-titles', 'duplicate'[$is-duplicate]),
    $root/guide/chapter-list/chapter/toc:guide(doc(@href)/chapter/node()))
};

declare function toc:guide-node(
  $root as document-node())
as element(toc:node)
{
  toc:guide-node($root, false())
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
    case $api:MODE-JAVASCRIPT return 'js/'
    default return '',
    $id,
    '.html')
};

(: Rewrite rendered node id as needed for javascript.
 : For the toc_filter javascript this needs to be a valid xs:ID,
 : so we use 'js_' instead of 'js/'.
 : TODO build this into the original toc:node generation instead?
 :)
declare function toc:node-id(
  $node as element(toc:node))
as xs:ID
{
  xs:ID(
    concat(
      if ($node/@mode eq $api:MODE-JAVASCRIPT) then 'js_'
      else '',
      $node/@id))
};

declare function toc:uri-save(
  $uri as xs:string,
  $location as xs:string)
as empty-sequence()
{
  stp:info('toc:uri-save', ($uri, '=>', $location)),
  xdmp:document-insert($location, element api:toc-uri { $uri })
};

(: Given a node, return appropriate HTML classnames. :)
declare function toc:render-node-class(
  $n as element(toc:node))
as xs:string*
{
  if ($n[@open]) then 'collapsible'
  else if ($n[toc:node]) then 'expandable'
  else (),

  let $following := $n/following-sibling::*
  return (
    if ($following) then () else (
      if ($n/@open) then 'lastCollapsible'
      else if ($n/toc:node) then 'lastExpandable'
      else 'last'))
  ,

  (: Include on nodes that will be loaded asynchronously. :)
  'hasChildren'[$n/@async],

  (: Include on nodes that have an @id
   : (used by list pages to identify the relevant TOC section)
   : but that aren't loaded asynchronously
   : because they're already loaded.
   :)
  ("loaded", 'initialized')[$n[@id][not(@async)]],

  (: Mark the asynchronous (unpopulated) nodes as such,
   : for the treeview JavaScript.
   :)
  "async"[$n/@async],

  (: Mark the nodes whose descendant titles should be wrapped :)
  "wrapTitles"[$n/@wrap-titles]
};

declare function toc:render-node-display(
  $n as element(toc:node))
as node()+
{
  text { $n/@display },
  if (not($n/@function-count)) then ()
  else <span xmlns="http://www.w3.org/1999/xhtml" class="function_count">
  {
    concat(' (', $n/@function-count/string(), ')')
  }
  </span>
};

(: Given a node, render the hitarea for the treeview code. :)
declare function toc:render-node-link(
  $prefix-for-hrefs as xs:string?,
  $n as element(toc:node))
as element()
{
  let $display as node()+ := toc:render-node-display($n)
  return (
    if (not($n/@href)) then
    <span xmlns="http://www.w3.org/1999/xhtml">{ $display }</span>
    else
    <a xmlns="http://www.w3.org/1999/xhtml">
    {
      attribute href {
        (: When the @href value is just "/",
         : leave it out when the version is specified explicitly.
         : /4.2 instead of /4.2/
         :)
        concat(
          $prefix-for-hrefs,
          if ($prefix-for-hrefs and $n/@href eq '/') then ''
          else $n/@href) },

      if (not($n/@external)) then () else (
        attribute class { 'external' },
        attribute target { '_blank' }),

      $n/@namespace/attribute title { . },

      $display
    }
    </a>
  )
};

(: Given a node, render the hitarea for the treeview code. :)
declare function toc:render-node-hitarea(
  $n as element(toc:node))
as element()?
{
  if (not($n/toc:node)) then () else
  <div xmlns="http://www.w3.org/1999/xhtml">
  {
    let $has-children := exists($n/toc:node)
    let $following := $n/following-sibling::toc:node
    return attribute class {
      if ($n/@open) then ('hitarea', 'collapsible-hitarea')
      else if ($has-children) then ('hitarea', 'expandable-hitarea')
      else (),

      (: Is this the last hitarea? :)
      if ($following) then ()
      else if ($n/@open) then 'lastCollapsible-hitarea'
      else 'lastExpandable-hitarea' }
  }
  </div>
};

(: Given a node, render the children inline or as new documents. :)
declare function toc:render-node-children(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $n as element(toc:node))
as element()?
{
  if (not($stp:DEBUG)) then () else stp:fine(
    'toc:render-node-children',
    ($uri, $prefix-for-hrefs,
      xdmp:describe($n),
      exists($n/toc:node))),

  if (not($n/toc:node)) then () else
  <ul xmlns="http://www.w3.org/1999/xhtml">
  {
    attribute style {
      'display:',
      if ($n/@open) then 'block;' else 'none;' },
    if (not($n/@async)) then toc:render-node(
      $uri, $prefix-for-hrefs, $n/toc:node)
    (: Placeholder for nodes to be loaded asynchronously. :)
    else <li><span class="placeholder">&#160;</span></li>
  }
  </ul>
};

(: This is a TOC leaf node.
 : If async, its @id will point the way.
 :)
declare function toc:render-node(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $n as element(toc:node))
as element()
{
  if (not($stp:DEBUG)) then () else stp:fine(
    'toc:render-node',
    ($uri, $prefix-for-hrefs, xdmp:describe($n), xdmp:describe($n/toc:node))),
  <li xmlns="http://www.w3.org/1999/xhtml">
  {
    attribute class { toc:render-node-class($n) },
    if (not($n/@id)) then ()
    else attribute id { toc:node-id($n) },
    toc:render-node-hitarea($n),
    toc:render-node-link($prefix-for-hrefs, $n),
    toc:render-node-children($uri, $prefix-for-hrefs, $n)
  }
  </li>
};

(: Given a non-duplicate async node,
 : generate a new element with the correct base-uri.
 :)
declare function toc:render-async(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $n as element(toc:node))
as element()
{
  if ($n/@async and not($n/@duplicate)) then () else stp:error(
      'UNEXPECTED', xdmp:describe($n)),
  let $uri-new as xs:string := toc:uri(
    concat($uri, '/'),
    $n/@id/string() treat as xs:string,
    $n/@mode)
  let $_ := if (not($stp:DEBUG)) then () else stp:debug(
    'toc:render-async',
    ('async', 'not duplicate', 'mode', $n/@mode,
      $uri-new, xdmp:describe($n)))
  return <ul style="display: block;" xmlns="http://www.w3.org/1999/xhtml">
  {
    attribute xml:base { $uri-new },
    toc:render-node(
      $uri, $prefix-for-hrefs, $n/toc:node)
  }
  </ul>
};

declare function toc:render-content(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $toc as element(toc:root))
as element()
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:render-content',
    ($uri, $prefix-for-hrefs, xdmp:describe($toc))),
  <div id="tocs_all" class="toc_section" xmlns="http://www.w3.org/1999/xhtml">
    <div class="scrollable_section">
      <input id="config-filter" name="config-filter" class="config-filter"/>
      <img src="/apidoc/images/removeFilter.png" id="config-filter-close-button"
  class="config-filter-close-button"/>
      <div id="apidoc_tree_container" class="pjax_enabled">
  {
    element ul {
      attribute id { "apidoc_tree" },
      attribute class { "treeview" },
      element li {
        attribute id { "AllDocumentation" },
        attribute class { 'collapsible lastCollapsible' },
        <div class="hitarea collapsible-hitarea lastCollapsible-hitarea"></div>,
        element a {
          attribute href { $prefix-for-hrefs||'/' },
          attribute class { 'toc_root' },
          $toc/@display/string() },
        element ul {
          toc:render-node($uri, $prefix-for-hrefs, $toc/toc:node) } } }
  }
      </div>
    </div>
  </div>
};

(: All elements returned by this function must set a base-uri.
 : Functions from here on are free of side effects,
 : so start here for unit tests.
 :)
declare function toc:render(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $toc as element(toc:root))
as element()+
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:render',
    ($uri, $prefix-for-hrefs, xdmp:describe($toc))),

  (: The old XSL returned the async results first.
   : Do the same to make testing easier.
   :)
  toc:render-async(
    $uri, $prefix-for-hrefs,
    $toc//toc:node[@async][not(@duplicate)]),

  (: Wrapper includes placeholder elements for use by toc_filter.js toc_init.
   : Could some of this chrome move into page rendering?
   :)
  <div id="all_tocs" xml:base="{ $uri }"
       xmlns="http://www.w3.org/1999/xhtml">
    <div id="toc" class="toc">
      <div id="toc_content">
  {
    toc:render-content($uri, $prefix-for-hrefs, $toc)
  }
      </div>
      <div id="splitter"/>
    </div>
    <div id="tocPartsDir" style="display:none;">
  {
    concat($uri, '/')
  }
    </div>
  </div>
};

declare function toc:render(
  $uri as xs:string,
  $is-default as xs:boolean)
as empty-sequence()
{
  stp:info(
    'toc:render', ($is-default, $stp:toc-xml-uri, '=>', $uri)),
  (: Every result element must set its own base-uri,
   : so we known where to store it in the database.
   :)
  let $m-seen := map:map()
  for $n in toc:render(
    $uri,
    if ($is-default) then () else concat("/", $api:version),
    doc($stp:toc-xml-uri)/* treat as element())
  (: Force an error if the base-uri was not set. :)
  let $uri-new as xs:anyURI := base-uri($n)
  order by $uri-new
  return (
    stp:info('toc:render', ('inserting', $uri-new)),
    if (map:get($m-seen, $uri-new)) then stp:error('CONFLICT', $uri-new)
    else map:put($m-seen, $uri-new, $uri-new),
    xdmp:document-insert($uri-new, $n))
};

declare function toc:render()
as empty-sequence()
{
  toc:uri-save($stp:toc-uri, $api:toc-uri-location),
  toc:render($stp:toc-uri, false()),

  (: If we are processing the default version,
   : then we need to render another copy of the TOC
   : that does not include version numbers in its href links.
   :)
  if (not($stp:processing-default-version)) then ()
  else (
    toc:uri-save(
      $stp:toc-uri-default-version,
      $api:toc-uri-default-version-location),
    toc:render($stp:toc-uri-default-version, true()))
};

(: Input may be a document-node or element. :)
declare function toc:help-extract-title(
  $content as node())
as xs:string?
{
  (: Wildcard because sometimes the source uses XHTML, but sometimes not.
   : e.g., x509.xsd
   :)
  normalize-space(
    ($content//*:span[@class eq 'help-text'])[1])[.]
};

declare function toc:help-resolve-repeat(
  $e as element(repeat))
as element()
{
  let $qname := resolve-QName($e/@name, $e)
  let $idref := $e/@idref/string()
  return root($e)//*[@id eq $idref or node-name(.) eq $qname]
};

declare function toc:help-auto-exclude(
  $xsd-docs as document-node()*,
  $e as element())
as xs:string*
{
  (: For each of the other applicable elements in the same namespace :)
  let $version := number($api:version)
  let $ns := namespace-uri($e)
  for $other in root($e)//*[namespace-uri(.) eq $ns][not(. is $e)][
    not(@added-in) or @added-in le $version]
  let $this-name := local-name($other)
  (: Automatically exclude this name, its plural forms,
   : and whatever prefixed names it might stand for.
   :)
  return (
    toc:help-prefixed-names($xsd-docs, $other),
    $this-name,
    concat($this-name,'s'),
    concat($this-name,'es'))
};

declare function toc:help-path(
  $help-root-href as xs:string,
  $e as element())
{
  concat(
    $help-root-href,
    '/',
    if ($e/@url-name) then $e/@url-name
    else local-name($e))
};

declare function toc:help-element-decl(
  $xsd-docs as document-node()*,
  $e as element())
as element()
{
  let $ns := namespace-uri($e)
  let $local-name := local-name($e)
  (: Is this good enough?
   : Are there schemas with no targetNamespace?
   : Are there schemas that use namespace prefixes?
   :)
  return ($xsd-docs/xs:schema[@targetNamespace eq $ns]/xs:element[
    @name eq $local-name])[1]
};

(: Look in the XSD to grab the list of child element names.
 : TODO easier way to do this? Request-level caching?
 :)
declare function toc:help-option-names(
  $xsd-docs as document-node()*,
  $e as element())
as xs:string*
{
  let $decl as element() := toc:help-element-decl($xsd-docs, $e)
  let $complexType := root($decl)/*/xs:complexType[
    @name/resolve-QName(string(.), ..)
    eq $decl/@type/resolve-QName(string(.), ..)]
  return $complexType//xs:element/@ref/local-name-from-QName(
    resolve-QName(string(.), ..))
};

(: All the child element names having the given prefix :)
declare function toc:help-prefixed-names(
  $xsd-docs as document-node()*,
  $e as element())
as xs:string*
{
  let $sw as xs:string? := $e/@starting-with
  where $sw
  return toc:help-option-names($xsd-docs, $e)[starts-with(., $sw)]
};

(: All the child element names *not* having the given prefix :)
declare function toc:help-not-prefixed-names(
  $xsd-docs as document-node()*,
  $e as element())
as xs:string*
{
  let $sw as xs:string? := $e/@starting-with
  return toc:help-option-names($xsd-docs, $e)[not(starts-with(., $sw))]
};

(: Create sub-page list item for toc:intro with sub-categories.
 :)
declare function toc:li-for-sub-page(
  $n as element(toc:node))
as element(xhtml:li)
{
  <li xmlns="http://www.w3.org/1999/xhtml">
  {
    element a {
      $n/@href,
      $n/@category-name/string() }
  }
  </li>
};

declare function toc:lib-sub-pages(
  $mode as xs:string,
  $m-mode-functions as map:map,
  $by-bucket as element(toc:node)+,
  $lib as xs:string)
as element()*
{
  (: Hack to exclude semantic functions,
   : because the XQuery lib is just a placeholder.
   :)
  let $current-href as xs:string := concat(
    '/', (if ($mode eq $api:MODE-JAVASCRIPT) then 'js/' else ''),
    $lib, '/')
  let $excluded-prefix := (
    if ($mode eq $api:MODE-JAVASCRIPT) then '/js/sem'
    else '/sem')
  (: The sub-pages should be children of the toc:node for $lib.
   : TODO hotspot - provide map where key is href prefix?
   :)
  let $sub-pages := $by-bucket/(toc:node|toc:node/toc:node)[
    starts-with(@href, $current-href)][
    not(starts-with(@href, $excluded-prefix))]
  let $_ := if (not($stp:DEBUG)) then () else stp:fine(
    'toc:lib-sub-pages', ($current-href, xdmp:describe($sub-pages)))
  where $sub-pages
  return <div xmlns="http://www.w3.org/1999/xhtml">
  {
    <p>You can also view these functions broken down by category:</p>,
    element ul {
      for $i in $sub-pages
      order by $i/@category-name
      return toc:li-for-sub-page($i) }
  }
  </div>
};

declare function toc:function-count(
  $mode as xs:string,
  $lib as xs:string?)
as xs:integer
{
  xdmp:estimate(
    cts:search(
      collection(),
      cts:and-query(
        (cts:directory-query(api:version-dir($api:version), "1"),
          cts:element-attribute-value-query(
            xs:QName('api:function-page'),
            xs:QName('mode'),
            $mode),
          if (not($lib)) then ()
          else cts:element-attribute-value-query(
            xs:QName('api:function'), xs:QName('lib'), $lib)))))
};

declare function toc:category-href(
  $category as xs:string,
  $subcategory as xs:string,
  $is-exhaustive as xs:boolean,
  $use-category as xs:boolean,
  $mode as xs:string,
  $one-subcategory-lib as xs:string?,
  $main-subcategory-lib as xs:string?)
as xs:string
{
  if (not($stp:DEBUG)) then () else stp:fine(
    'toc:category-href',
    ('category', $category, 'subcat', $subcategory,
      'is-exhaustive', $is-exhaustive, 'use-category', $use-category,
      'mode', $mode,
      'one-subcat', xdmp:describe($one-subcategory-lib),
      'main-subcat', xdmp:describe($main-subcategory-lib))),
  (: The initial empty string ensures a leading '/'. :)
  string-join(
    ('',
      switch($mode)
      case $api:MODE-JAVASCRIPT return 'js'
      default return (),
      if ($is-exhaustive) then $one-subcategory-lib
      (: Include category in path - eg usually for REST :)
      else if ($use-category) then (
        $one-subcategory-lib,
        toc:path-for-category($category),
        toc:path-for-category($subcategory))
      else (
        $main-subcategory-lib,
        toc:path-for-category($subcategory))),
    '/')
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
    (: By default, just use alphabetical order.
     : But for REST docs, first sort by the resource name
     : and then the HTTP method.
     :)
    let $not-rest := not($f/@lib eq $api:MODE-REST)
    let $mode as attribute() := $f/@mode
    let $fullname as xs:string := $f/@fullname
    order by
      if ($not-rest) then $fullname
      else api:name-from-REST-fullname($fullname),
      if ($not-rest) then ()
      else api:verb-sort-key-from-REST-fullname($fullname)
    return element api:function-name {
      if (not($stp:DEBUG)) then () else stp:debug(
        'toc:function-name-nodes',
        ('function', xdmp:describe($f), 'not-rest', $not-rest,
          'mode', $mode, 'fullname', $fullname)),
      $mode,
      $fullname } }
  (: Why exclude some prefixes?
   : Because there is a hack that has a blank function in the
   : xquery module bucket for some prefixes: semantics, now also temporal.
   : This is because these libraries include both built-in and library functions.
   :)
  return $wrapper/api:function-name[not(. = ('sem:', 'temporal:'))]
};

declare function toc:function-node(
  $function-name as element(api:function-name),
  $version-number as xs:double)
as element(toc:node)
{
  (: TODO can we rely on mode for REST,
   : or check starts-with($function-name, '/') instead?
   :)
  let $mode as xs:string := $function-name/@mode
  let $_ := (
    if ($mode ne $api:MODE-REST
      and starts-with($function-name, '/')) then stp:error(
      'ASSERT',
      (xdmp:describe($mode),
        $function-name, xdmp:describe($function-name)))
    else ())
  let $display as xs:string := (
    switch($mode)
    case $api:MODE-JAVASCRIPT return api:javascript-name($function-name)
    case $api:MODE-REST return api:reverse-translate-REST-resource-name(
      (: For 5.0 hide the verb. :)
      if ($version-number gt 5.0) then $function-name
      else api:name-from-REST-fullname($function-name))
    default return $function-name)
  let $href as xs:string := (
    switch($mode)
    case $api:MODE-REST return api:REST-fullname-to-external-uri(
      $function-name)
    default return '/'||$display)
  let $type as xs:string := (
    switch($mode)
    case $api:MODE-JAVASCRIPT return 'javascript-function'
    default return 'function')
  return toc:node(
    toc:id($function-name), $display, $href,
    (), $type, (), ())
};

declare function toc:function-nodes(
  $version-number as xs:double,
  $functions as element(api:function)*)
as element(toc:node)*
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:function-nodes',
    (xdmp:describe($functions), $version-number)),
  toc:function-node(
    toc:function-name-nodes($functions), $version-number)
};

declare function toc:render-summary(
  $summary as element(apidoc:summary))
as element()
{
  stp:fixup($summary, 'toc')
  ! (
    (: Wrap summary content with <p> if not already present.
     : The wrapper might be in several namespaces.
     :)
    if (not($summary[not(xhtml:p|apidoc:p|p)])) then .
    else <p xmlns="http://www.w3.org/1999/xhtml">{ . }</p>)
};

declare function toc:functions-by-category-subcat-node(
  $version-number as xs:double,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $cat as xs:string,
  $is-REST as xs:boolean,
  $single-lib-for-category as xs:string?,
  $subcat as xs:string,
  $in-this-subcategory as element(api:function)+)
as element(toc:node)
{
  let $one-subcategory-lib := toc:lib-for-all($in-this-subcategory)
  let $main-subcategory-lib := toc:primary-lib($in-this-subcategory)
  let $secondary-lib := (
    if ($one-subcategory-lib) then ()
    else ($in-this-subcategory/@lib[not(. eq $main-subcategory-lib)])[1])
  let $is-exhaustive := toc:category-is-exhaustive(
    $m-mode-functions, $cat, $subcat, $one-subcategory-lib)
  return toc:node(
    toc:id(),
    (: If just one library is represented in this sub-category,
     : and if the parent category doesn't already display it,
     : only display, e.g, "xdmp:" in parens.
     :)
    toc:display-category($subcat)||(
      if (not($one-subcategory-lib and not($single-lib-for-category))) then ()
      else toc:display-suffix($one-subcategory-lib)),
    toc:category-href(
      $cat, $subcat,
      $is-exhaustive, $is-REST,
      $mode, $one-subcategory-lib, $main-subcategory-lib),
    (), (), ('function-list-page'),
    (
      (: If this is lib-exhaustive we already have the intro text. :)
      if ($is-exhaustive) then ()
      else attribute category-name { toc:display-category($subcat) },
      if ($is-REST) then toc:REST-page-title($cat, $subcat)
      else toc:category-page-title(
        $subcat, $main-subcategory-lib, $secondary-lib),
      element toc:intro {
        toc:render-summary(
          toc:get-summary-for-category(
            $mode, $cat, $subcat, $main-subcategory-lib)) },
      (: function TOC node :)
      toc:function-nodes($version-number, $in-this-subcategory)))
};

declare function toc:functions-by-category-subcat(
  $version-number as xs:double,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $cat as xs:string,
  $is-REST as xs:boolean,
  $in-this-category as element()+,
  $single-lib-for-category as xs:string?,
  $sub-categories as xs:string+)
as element(toc:node)+
{
  let $m-catsubcat := map:get($m-mode-functions, $MAP-KEY-CATSUBCAT)
  for $subcat in $sub-categories
  let $in-this-subcategory as element(api:function)+ := map:get(
    $m-catsubcat, $cat||'#'||$subcat)
  order by $subcat
  return toc:functions-by-category-subcat-node(
    $version-number, $mode, $m-mode-functions,
    $cat, $is-REST,
    $single-lib-for-category, $subcat, $in-this-subcategory)
};

(: TODO refactor. :)
declare function toc:functions-by-category(
  $version-number as xs:double,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $bucket-id as xs:string,
  $cat as xs:string,
  $is-REST as xs:boolean,
  $in-this-category as element(api:function)+)
as element(toc:node)+
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:functions-by-category', ($version-number, $mode)),
  let $single-lib-for-category := toc:lib-for-all($in-this-category)
  let $is-exhaustive := toc:category-is-exhaustive(
    $m-mode-functions, $cat, (), $single-lib-for-category)
  let $sub-categories as xs:string* := distinct-values(
    $in-this-category/@subcategory)
  (: When there are sub-categories, don't create a new page for the category.
   : They tend to be useless.
   : Only create a link if it corresponds to a full lib page,
   : or if it doesn't contain sub-categories
   : and does not already correspond to a full lib page,
   : unless it is a REST doc category,
   : in which case we do want to create the category page
   : (e.g., for Client API).
   :)
  let $href := (
    if (not($is-exhaustive or (not($sub-categories) or $is-REST))) then ()
    else toc:category-href(
      $cat, $cat, $is-exhaustive,
      false(), $mode,
      if ($is-exhaustive) then $single-lib-for-category else '',
      if ($is-exhaustive) then '' else $single-lib-for-category))
  return toc:node(
    $bucket-id||'_'||translate($cat, ' ' , ''),
    toc:display-category($cat)||toc:display-suffix($single-lib-for-category),
    $href,
    (), (), ('function-list-page'),
    (attribute mode { $mode },

      (: ASSUMPTION
       : $single-lib-for-category is supplied/applicable
       : if we are in this code branch;
       : in other words, every top-level category page
       : only pertains to one library
       : (sub-categories can have more than one; see below).
       :)
      if ($is-exhaustive or ($sub-categories and not($is-REST))) then ()
      else (
        attribute category-name { toc:display-category($cat) },
        if ($is-REST) then toc:REST-page-title($cat, ())
        else toc:category-page-title($cat, $single-lib-for-category, ()),
        element toc:intro {
          toc:render-summary(
            toc:get-summary-for-category(
              $mode, $cat, (), $single-lib-for-category)) }),

      (: ASSUMPTION
       : A category has either functions as children or sub-categories,
       : never both.
       :)
      (: Are these function TOC nodes? :)
      if (not($sub-categories)) then toc:function-nodes(
        $version-number, $in-this-category)
      else toc:functions-by-category-subcat(
        $version-number, $mode, $m-mode-functions,
        $cat, $is-REST,
        $in-this-category, $single-lib-for-category, $sub-categories)))
};

declare function toc:functions-by-bucket(
  $version-number as xs:double,
  $m-mode-functions as map:map,
  $mode as xs:string)
as element(toc:node)+
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:functions-by-bucket', ($version-number, $mode)),
  let $m-buckets as map:map := map:get($m-mode-functions, $MAP-KEY-BUCKET)
  let $forced-order := (
    'MarkLogic Built-In Functions',
    'XQuery Library Modules', 'CPF Functions',
    'W3C-Standard Functions', 'REST Resources API')
  for $b in map:keys($m-buckets)
  (: bucket node
   : ID for function buckets is the display name minus spaces.
   : async is ignored for REST, because we ignore this toc:node.
   :)
  let $bucket-id := (
    if ($mode eq $api:MODE-JAVASCRIPT) then 'js_'
    else '')||translate($b, ' ', '')
  let $is-REST := $mode eq $api:MODE-REST
  order by index-of($forced-order, $b) ascending, $b
  return toc:node(
    $bucket-id, $b, (),
    true(), (), ('sub-control'),
    (attribute mode { $mode },
      let $m-cats := map:get($m-buckets, $b)
      for $cat in map:keys($m-cats)
      order by $cat
      return toc:functions-by-category(
        $version-number, $mode, $m-mode-functions,
        $bucket-id, $cat, $is-REST, map:get($m-cats, $cat))))
};

declare function toc:help-fixup(
  $n as node())
as node()
{
  (: Convert hard-coded color spans into <strong> tags.
   : Namespaces are not consistent in help docs.
   :)
  if ($n/self::*:span[contains(@style, 'color:')]) then element strong {
    attribute class { 'configOption' },
    toc:help-fixup($n/node()) }
  (: Rewrite image URLs. These should always be empty. :)
  else if ($n/self::*:img[@src]) then element img {
    $n/@* except ($n/@src, $n/@class),
    attribute src { concat('/apidoc/images/admin-help/', $n/@src) },
    attribute class { 'adminHelp' } }
  else if ($n/self::*) then element { node-name($n) } {
    $n/@*,
    toc:help-fixup($n/node()) }
  else $n
};

declare function toc:help-content-element(
  $version-number as xs:double,
  $xsd-docs as document-node()*,
  $e as element())
as node()+
{
  let $exclusion-list := (
    tokenize($e/@exclude, '\s+'),
    if ($e/@starting-with) then toc:help-not-prefixed-names($xsd-docs, $e)
    else if ($e/@auto-exclude) then toc:help-auto-exclude($xsd-docs, $e)
    else ())
  let $help-content := element api:help-node {
    af:displayHelp(
      toc:help-element-decl($xsd-docs, $e)/root()/*, (: $schemaroot :)
      local-name($e),
      if ($e/@help-position eq 2) then 2 else 1, (: $multiple-uses :)
      $exclusion-list,
      tokenize($e/@line-after, '\s+'),
      not($e/@append) (: $print-buttons :) ) }
  let $title as xs:string+ := (
    if ($e/@content-title) then $e/@content-title
    else toc:help-extract-title($help-content)[1])
  (: ASSUMPTION The title of the page appears at the beginning,
   : between two hr elements.
   : But the page for flexrep-domain is missing the second hr.
   :)
  let $body as node()+ := toc:help-fixup(
    $help-content/(
      if (*:hr[2]) then *:hr[2]/following-sibling::node()
      else *:span[1]/following-sibling::node()))
  return toc:node(
    toc:id($e), $e/@display, toc:help-path($HELP-ROOT-HREF, $e),
    (), (), 'admin-help-page',
    (element toc:title { $title },
      element toc:content {
        if ($e/@show-only-the-list) then ($body//*:ul)[1]
        else $body },
      (: Recurse on any children. :)
      toc:help-content($version-number, $xsd-docs, $e/*)))
};

declare function toc:help-content(
  $version-number as xs:double,
  $xsd-docs as document-node()*,
  $e as element())
as node()+
{
  (: Ignore sections that were added in a later server version :)
  if ($version-number lt $e/@added-in) then ()
  else typeswitch($e)
  case element(repeat) return toc:help-content(
    $version-number, $xsd-docs, toc:help-resolve-repeat($e))
  case element(container) return toc:node(
    toc:id($e), $e/@display,
    toc:help-content($version-number, $xsd-docs, $e/*))
  default return toc:help-content-element($version-number, $xsd-docs, $e)
};

declare function toc:help(
  $version-number as xs:double,
  $xsd-docs as document-node()*,
  $help as element(help))
as element(toc:node)
{
  toc:node(
    "HelpTOC", $help/@display, $HELP-ROOT-HREF,
    (), (), ('admin-help-page'),
    (element toc:title { 'Admin Interface Help Pages' },
      element toc:content {
        attribute auto-help-list { true() },
        toc:help-content($version-number, $xsd-docs, $help/*) }))
};

(:
 : This creates an XML TOC section for a library, with an id.
 : The api:lib elements are generated in api:get-libs.
 : This is javascript-aware.
 :)
declare function toc:api-lib(
  $version-number as xs:double,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $by-bucket as element(toc:node)+,
  $lib as element(api:lib))
as element(toc:node)
{
  toc:node(
    concat($lib, '_', toc:id($lib)),
    concat(
      api:prefix-for-lib($lib),
      if ($mode eq $api:MODE-JAVASCRIPT) then '.' else ':'),
    concat(
      if ($mode eq $api:MODE-JAVASCRIPT) then '/js/' else '/',
      $lib),
    true(), (), ('function-list-page', 'footnote'[$lib/@built-in]),
    ($lib/@category-bucket,
      attribute function-count { toc:function-count($mode, $lib) },
      attribute namespace { api:namespace($lib)/@uri },
      attribute mode { $mode },

      element toc:title {
        api:prefix-for-lib($lib), 'functions' },
      element toc:intro {
        <p xmlns="http://www.w3.org/1999/xhtml">
        The table below lists all the
        {
          api:prefix-for-lib($lib),
          if ($lib/@built-in) then 'built-in' else 'XQuery library'
        }
        functions (in this namespace: <code>{ api:namespace($lib)/@uri }</code>).
        </p>,
        (: TODO Right now this really wants toc:nodes not functions. :)
        toc:lib-sub-pages($mode, $m-mode-functions, $by-bucket, $lib),
        (: Summary may be empty. :)
        $lib/toc:get-summary-for-lib(.)/toc:render-summary(.),
        api:namespace($lib)/summary-addendum/node()
      },
      comment { 'Current lib:', $lib },
      toc:function-nodes(
        $version-number,
        let $m-lib as map:map := map:get($m-mode-functions, $MAP-KEY-LIB)
        return map:get($m-lib, $lib)) ))
};

declare function toc:node-external(
  $display as xs:string,
  $href as xs:string)
{
  toc:node(
    toc:id(), $display, $href,
    (), (), 'external',
    ())
};

(: TODO refactor. :)
declare function toc:create(
  $version as xs:string,
  $xsd-docs as document-node()*)
as element(toc:root)
{
  let $version-number := xs:double($version)
  let $m-functions := toc:functions-map($version)
  let $m-by-bucket := map:new(
    $api:MODES ! map:entry(
      .,
      toc:functions-by-bucket(
        $version-number, map:get($m-functions, .), .)))
  let $function-count := toc:function-count($api:MODE-XPATH, ())
  let $javascript-function-count := toc:function-count($api:MODE-JAVASCRIPT, ())
  return element toc:root {
    attribute display { "All Documentation" },
    attribute open { true() },
    toc:node(
      toc:id(), "Server-Side APIs", (),
      (), (), 'open',

      (: JavaScript :)
      (if ($version-number lt 8) then () else (
        toc:node(
          'AllFunctionsJavasScriptByCat',
          "JavaScript Functions by Category ("
          ||$javascript-function-count||')',
          "/js/all",
          (), (), ('open'),
          (attribute mode { $api:MODE-JAVASCRIPT },
           map:get($m-by-bucket, $api:MODE-JAVASCRIPT))),

          toc:node(
            'AllFunctionsJavaScript',
            "JavaScript Functions ("||$javascript-function-count||')',
            "/js/all",
            (), (), ('open', 'function-list-page'),
            (attribute mode { $api:MODE-JAVASCRIPT },
              element toc:title { 'JavaScript Functions' },
              element toc:intro {
                <p xmlns="http://www.w3.org/1999/xhtml">
                The following table lists all JavaScript functions
                in the MarkLogic API reference,
                including both built-in functions
                and functions implemented in XQuery library modules.
                </p> },
              for $lib in $ALL-LIBS-JAVASCRIPT
              order by $lib
              return toc:api-lib(
                $version-number, $api:MODE-JAVASCRIPT,
                map:get($m-functions, $api:MODE-JAVASCRIPT),
                map:get($m-by-bucket, $api:MODE-JAVASCRIPT),
                $lib))))
        ,

        toc:node(
          'AllFunctionsByCat',
          "XQuery/XSLT Functions by Category ("||$function-count||')',
          "/all",
          (), (), ('open'),
          (attribute mode { $api:MODE-XPATH },
           map:get($m-by-bucket, $api:MODE-XPATH))),

        toc:node(
          'AllFunctions',
          "XQuery/XSLT Functions ("||$function-count||')',
          "/all",
          (), (), ('open', 'function-list-page'),
          (attribute mode { $api:MODE-XPATH },
            element toc:title { 'XQuery/XSLT Functions' },
            element toc:intro {
              <p xmlns="http://www.w3.org/1999/xhtml">
              The following table lists all XQuery/XSLT functions
              in the MarkLogic API reference,
              including both built-in functions
              and functions implemented in XQuery library modules.
              </p> },
            for $lib in $ALL-LIBS
            order by $lib
            return toc:api-lib(
              $version-number, $api:MODE-XPATH,
              map:get($m-functions, $api:MODE-XPATH),
              map:get($m-by-bucket, $api:MODE-XPATH),
              $lib)))))
    ,

    (: REST API :)
    if ($version-number lt 5) then () else toc:node(
      "RESTResourcesAPI", "REST Resources", '/REST',
      (), (), ('function-list-page', 'open'),
      (
        element toc:title { 'REST resources' },
        map:get($m-by-bucket, $api:MODE-REST),
        toc:node(
          "RelatedRestGuides", "Related Guides", (),
          (), (), 'open',
          (: Repeat REST client guide, Monitoring guide. :)
          ($GUIDE-DOCS[ends-with(base-uri(.), 'rest-dev.xml')]
            /toc:guide-node(., true()),
            $GUIDE-DOCS[ends-with(base-uri(.),'monitoring.xml')]
            /toc:guide-node(., true())))))
    ,

    if ($version-number lt 6) then () else toc:node(
      toc:id(), "Client-Side APIs", (),
      (), (), 'open',
      toc:node(
        "javaTOC", "Java API", "/javadoc/client/index.html",
        (), (), ('external'),
        (: Java Client guide repeated. :)
        $GUIDE-DOCS[ends-with(base-uri(.),'java.xml')]
        /toc:guide-node(., true()))),

    toc:node(
      "guides", "Guides", (),
      (), (), 'open',
      (if (not($GUIDE-DOCS-NOT-CONFIGURED)) then () else toc:node(
          toc:id(),
          "New (unclassified) guides", (),
          (), (), 'open',
          $GUIDE-DOCS-NOT-CONFIGURED/toc:guide-node(.))
        ,
        for $guide in $GUIDE-GROUPS
        return toc:node(
          toc:id($guide), $guide/@name, (),
          (: Per #204 hard-code open state by guide. :)
          (), (), ('open'[$guide/@name = ('Getting Started Guides')]),
          $guide/toc:guides-in-group(.)/toc:guide-node(.))))
    ,

    toc:node(
      "other", "Other Documentation", (),
      (), (), 'open',
      (if ($version-number lt 5) then () else toc:node(
          toc:id(), 'Hadoop Connector', (),
          (), (), (),
          toc:node(
            toc:id(),
            "Connector for Hadoop API",
            "/javadoc/hadoop/index.html",
            (), (), 'external',
            (: Hadoop guide repeated :)
            $GUIDE-DOCS[ends-with(base-uri(.),'mapreduce.xml')]
            /toc:guide-node(., true()))),

        toc:node(
          toc:id(), "XCC", (),
          (toc:node-external(
              "XCC Javadoc", "/javadoc/xcc/index.html"),
            toc:node-external(
              "XCC .NET API", "/dotnet/xcc/index.html"),
            (: XCC guide repeated :)
            $GUIDE-DOCS[ends-with(base-uri(.),'xcc.xml')]
            /toc:guide-node(., true()))),

        toc:help(
          $version-number,
          $xsd-docs,
          u:get-doc('/apidoc/config/help-config.xml')/help),

        if ($version-number lt 6) then () else toc:node-external(
          "C++ UDF API Reference", "/cpp/udf/index.html"))) }
};

declare function toc:xsd-docs($path as xs:string)
as document-node()*
{
  xdmp:document-get(
    xdmp:filesystem-directory($path)/dir:entry[
      dir:type eq 'file'][
      ends-with(dir:pathname, '.xsd')]/dir:pathname)
};

declare function toc:toc(
  $version as xs:string,
  $xsd-path as xs:string)
as empty-sequence()
{
  $stp:helpXsdCheck,
  stp:info('toc:toc', ("Creating new TOC at", $stp:toc-xml-uri)),
  xdmp:document-insert(
    $stp:toc-xml-uri,
    toc:create($version, toc:xsd-docs($xsd-path))),
  stp:info('toc:toc', xdmp:elapsed-time())
};

(: apidoc/setup/toc.xqm :)
