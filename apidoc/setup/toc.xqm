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
 : of categories to URIs.
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
  $node as element(toc:node))
as xs:ID
{
  xs:ID(
    concat(
      if (xs:boolean($node/@is-javascript)
        or $node/@type = 'javascript-function') then 'js_'
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
  stp:fine(
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
  stp:fine(
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
  let $uri-child := toc:uri(
    concat($uri, '/'),
    $n/@id,
    (: Handle javascript functions. :)
    if ($n[@is-javascript]) then 'javascript'
    else ())
  let $_ := stp:fine(
    'toc:render-async',
    ('async', 'not duplicate', $uri-child, xdmp:describe($n)))
  return <ul style="display: block;" xmlns="http://www.w3.org/1999/xhtml">
  {
    attribute xml:base { $uri-child },
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
  stp:debug(
    'toc:render-content',
    ($uri, $prefix-for-hrefs, xdmp:describe($toc))),
  <div id="tocs-all" class="toc_section" xmlns="http://www.w3.org/1999/xhtml">
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

declare function toc:render-root(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $toc as element(toc:root))
as element()+
{
  stp:debug(
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

(: All elements returned by this function must set a base-uri.
 : Functions from here on are free of side effects,
 : so start here for unit tests.
 :)
declare function toc:render(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $toc-document as document-node())
as node()+
{
  (: TODO when xqy is working, remove xsl entirely. :)
 if (0) then xdmp:xslt-invoke(
    "render-toc.xsl",
    $toc-document,
    map:new(
      (map:entry('toc-uri', $uri),
        map:entry('prefix-for-hrefs', $prefix-for-hrefs),
        map:entry('version', $api:version))))
  else toc:render-root(
    $uri,
    $prefix-for-hrefs,
    $toc-document/* treat as node())
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
  toc:render(
    $uri,
    if ($is-default) then () else concat("/", $api:version),
    doc($stp:toc-xml-uri) treat as node())/
  xdmp:document-insert(
    (: Force an error if the base-uri was not set. :)
    base-uri(.) treat as xs:anyURI,
    .)
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

(: apidoc/setup/toc.xqm :)