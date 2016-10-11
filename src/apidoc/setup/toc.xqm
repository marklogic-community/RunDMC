xquery version "1.0-ml";
(: TOC setup functions. :)

module namespace toc="http://marklogic.com/rundmc/api/toc" ;

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";
import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

(: We look back into the raw docs database
 : to get the introductory content for each function list page.
 :)
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "/apidoc/setup/raw-docs-access.xqy" ;

declare namespace admin="http://marklogic.com/xdmp/admin" ;
declare namespace apidoc="http://marklogic.com/xdmp/apidoc" ;
declare namespace xhtml="http://www.w3.org/1999/xhtml" ;

declare variable $ML-VERSION := xs:integer(
  substring-before(xdmp:version(), '.')) ;

(: This is for specifying exceptions to the automated mappings
 : of categories to URIs.
 :)
declare variable $CATEGORY-MAPPINGS := u:get-doc(
  '/apidoc/config/category-mappings.xml')/*/category ;

declare variable $HELP-ROOT-HREF := '/admin-help' ;

declare variable $MAP-KEY-BUCKET := 'BUCKET' ;
declare variable $MAP-KEY-CATSUBCAT := 'CATSUBCAT' ;
declare variable $MAP-KEY-LIB := 'LIBRARY' ;

declare function toc:directory-uri($version as xs:string)
as xs:string
{
  concat("/media/apiTOC/", $version, "/")
};

declare function toc:root-uri($version as xs:string)
as xs:string
{
  concat(toc:directory-uri($version), "toc.xml")
};

declare function toc:html-uri(
  $version as xs:string)
as xs:string
{
  concat(
    toc:directory-uri($version),
    "apiTOC_", current-dateTime(),
    ".html")
};

(: Normally just use the lib name as the prefix,
 : unless specially configured to do otherwise.
 :)
declare function toc:prefix-for-lib(
  $lib as xs:string)
as xs:string?
{
  (api:namespace($lib)/@prefix,
    $lib)[1]
};

declare function toc:functions-map(
  $version as xs:string,
  $m as map:map)
as empty-sequence()
{
  let $functions-all as item()+ := api:functions-all($version)
  for $f in $functions-all
  let $fp := $f/api:function-page
  let $f1 := $fp/api:function[1]
  let $mode as xs:string := $fp/@mode
  let $m-mode := map:get($m, $mode)
  let $bucket as xs:string := if ($f1/@bucket)
                              then ($f1/@bucket)
                              else ('MarkLogic Built-In Functions')
  let $cat as xs:string := $f1/@category
  let $subcat as xs:string? := $f1/@subcategory
  let $catsubcat as xs:string := $cat||'#'||$subcat
  let $lib := $f1/@lib/fn:string()
  let $object := $f1/@object/fn:string()
  (:
     either $lib or $object (used with apidoc:method) should be the
     empty string, but we are treating them both like lib
  :)
  let $lib-or-object := fn:concat($lib, $object)
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
    $m-lib, $lib-or-object, (map:get($m-lib, $lib-or-object), $f1))
  return ()
};

(: Prestructured map by mode,
 : containing maps by bucket, category+subcategory, and lib.
 : This allows easy access to all the grouping info
 : after one pass through the function sequence.
 :)
declare function toc:functions-map(
  $version as xs:string)
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
  let $_ := toc:functions-map($version, $m)
  let $_ := $api:MODES ! (
    if (map:count(map:get(map:get($m, .), $MAP-KEY-BUCKET))) then ()
    else if (. eq $api:MODE-JAVASCRIPT and number($version) lt 8.0) then ()
    else stp:error('BAD', ('No functions for mode', .)))
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
  let $prefix := toc:prefix-for-lib($lib)
  let $secondary-prefix :=
    if ($secondary-lib) then
      toc:prefix-for-lib($secondary-lib)
    else ()
  return
    element toc:title {
      (: Children will be in the default element namespace,
       : which is empty.
       :)
      element a {
        attribute href { "/" || $lib },
        $prefix
      },
      if (not($secondary-lib)) then (
        if ($prefix) then
          ' functions ('|| toc:display-category($cat) || ')'
        else
          toc:display-category($cat)
      )
      else (
        ' and ',
        element a {
          attribute href { "/" || $secondary-lib },
          $secondary-prefix
        },
        if ($secondary-prefix) then
          ' functions (' || toc:display-category($cat) ||' )'
        else
          toc:display-category($cat)
      )
    }
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
    fn:string-join(
      (
        $category,
        if (not($subcategory)) then ()
        else (
          '('||$subcategory||')'
        )
      ),
      ' '
    )
  }
};

(: Returns the one library string if all the functions are in the same library.
 : Otherwise returns empty.
 :)
declare function toc:lib-for-all(
  $functions as element()*)
as xs:string?
{
  let $libs := distinct-values(($functions/@lib, $functions/@object))
  (: This is a hack to make the semantics library work.
   : It has multiple namespace.
   :)
  return (
    if (count($libs) eq 1) then ($functions/(@lib | @object))[1]
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
  (for $name in distinct-values(($functions/@lib, $functions/@object))
    let $count := count($functions[@lib eq $name])
    order by $count descending
    return $name)[1]
};

(:
 : Exhaustive means that all the category functions are in one lib
 : (ie, XQuery namespace or SJS object). For instance (as of writing this),
 : all the MathBuiltins are in math: and all functions in math: are in
 : MathBuiltins.
 :)
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

declare function toc:display-suffix(
  $lib as xs:string?,
  $mode as xs:string)
as xs:string?
{
  (: Don't display a suffix for REST categories :)
  if (not($lib) or $lib eq $api:MODE-REST) then ()
  else concat(
    ' (', toc:prefix-for-lib($lib),
    if ($mode eq $api:MODE-JAVASCRIPT) then '.' else ':',
    ')')
};

(: TODO refactor to read directly from zip. :)
declare function toc:modules-raw(
  $version as xs:string)
as element(apidoc:module)+
{
  raw:api-docs($version)/apidoc:module
};

(: Just grab the first summary. If we have a category with subcategories,
 : the following line of code can return multiple summaries.
 :)
declare function toc:find-primary-summary(
  $raw-modules as element()+,
  $cat as xs:string,
  $subcat as xs:string?,
  $mode as xs:string)
  as element(apidoc:summary)*
{
  let $summary :=
    ($raw-modules/apidoc:summary
      [@category eq $cat]
      [not($subcat) and not(@subcategory) or @subcategory eq $subcat]
      [not(@class) or @class eq $mode]
    )[1]
  return
    if ($summary) then $summary
    else
      $raw-modules
        [@category eq $cat]
        [not($subcat) or @subcategory eq $subcat]/apidoc:summary
};

declare function toc:get-summary-for-category(
  $version as xs:string,
  $mode as xs:string,
  $prefixes-not-builtin as xs:string*,
  $cat as xs:string,
  $subcat as xs:string?,
  $lib as xs:string?)
  as element(apidoc:summary)*
{
  let $raw-modules as element()+ := toc:modules-raw($version)
  let $summaries-with-category :=
    toc:find-primary-summary($raw-modules, $cat, $subcat, $mode)
  return (
    if ($summaries-with-category) then $summaries-with-category
    else (
      (: Fallback boilerplate is different for library modules
       : than for built-ins.
       :
       : The admin library sub-pages don't have their own descriptions.
       : So use this boilerplate instead
       :)
      if ($lib = $prefixes-not-builtin) then element apidoc:summary {
        <p>
        For information on how to import the functions in this module,
        refer to the main
        <a href="{
        concat(
        switch($mode)
        case $api:MODE-JAVASCRIPT return 'js/'
        default return '',
        $lib)
        }">{ toc:prefix-for-lib($lib) } library page</a>.
        </p>
      }

      (: ASSUMPTION Only REST sub-categories may need this fallback
       : all main categories (e.g., Client API and Management API)
       : already have summaries written
       :)
      else if ($lib eq $api:MODE-REST) then element apidoc:summary {
        <p>
        For the complete list of REST resources in this category,
        refer to the main <a href="/REST/{toc:path-for-category($cat)}">{
          toc:display-category($cat) } page</a>.
        </p>
      }

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
        }">{ toc:prefix-for-lib($lib) }
        functions page</a>.
        </p>
      }
    )
  )
};

(: We only want to see one summary :)
declare function toc:get-summary-for-lib(
  $version as xs:string,
  $lib as xs:string)
as element()?
{
  let $raw-modules as element()+ := toc:modules-raw($version)
  (: exceptional ("json" built-in) :)
  let $lib-subcat as xs:string? := api:namespace($lib)/@subcategory
  let $summaries-by-summary-subcat := $raw-modules/apidoc:summary[
    @subcategory eq $lib-subcat]
  (: exceptional ("spell" built-in) :)
  let $lib-cat as xs:string? := api:namespace($lib)/@category
  let $summaries-by-module-cat := $raw-modules[
    @category eq $lib-cat]/apidoc:summary
  (: the most common case :)
  let $lib-prefix := toc:prefix-for-lib($lib)
  let $summaries-by-module-lib := $raw-modules[
    @lib eq $lib-prefix]/apidoc:summary
  (: exceptional ("map") :)
  let $summaries-by-summary-lib := $raw-modules/apidoc:summary[
    @lib eq $lib-prefix]
  (: exceptional ("dls") :)
  let $summaries-by-module-lib-no-subcat := $summaries-by-module-lib[
    not(@subcategory)]
  let $summaries-by-object :=
    element apidoc:summary {
      let $obj := $raw-modules/apidoc:object[@name eq $lib]
      return (
        if ($obj/@subtype-of) then (
          element xhtml:p {
            element xhtml:code {$lib},
            " is a subtype of ",
            let $count := fn:count(fn:tokenize(fn:normalize-space(
                     $obj/@subtype-of/fn:string()), " "))
            return
              (: is there more than one subtype? :)
              if ($count eq 1) then (
                element xhtml:a {
                  attribute href {
                    toc:category-href(
                      $obj/@subtype-of/fn:string(), "",
                      fn:true(), fn:true(), $api:MODE-JAVASCRIPT,
                      $obj/@subtype-of/fn:string(), ""
                    )
                  },
                  $obj/@subtype-of/fn:string() || "."
                }
              )
              else
                for $subtype at $i in
                  fn:tokenize(fn:normalize-space($obj/@subtype-of/fn:string()), " ")
                return (
                  element xhtml:a {
                    attribute href {
                      toc:category-href(
                        $subtype, "",
                        fn:true(), fn:true(), $api:MODE-JAVASCRIPT,
                        $subtype, ""
                      )
                    },
                    $subtype
                  },
                  if ($i eq $count) then "." else " and "
                )
          }
        )
        else (),
        stp:node-to-xhtml($obj/apidoc:summary/node())
      )
    }
  return (
    if ($lib = $api:M-OBJECTS) then
      $summaries-by-object
    else if (count($summaries-by-summary-subcat) eq 1) then
      $summaries-by-summary-subcat
    else if (count($summaries-by-module-lib) eq 1) then
      $summaries-by-module-lib
    else if (count($summaries-by-summary-lib) eq 1) then
      $summaries-by-summary-lib
    else if (count($summaries-by-module-lib-no-subcat) eq 1) then
      $summaries-by-module-lib-no-subcat
    else ()
  )



};

declare function toc:guides-in-group(
  $version as xs:string,
  $groups as element(apidoc:group)*)
as document-node()*
{
  doc(
    $groups/apidoc:guide/concat(
      api:version-dir($version), 'guide/', @url-name, '.xml'))
};

(: Build a TOC href with fragment for this guide section.
 : Per #310 we do not actually use the chapter fragment.
 :)
declare function toc:guide-href(
  $e as element(xhtml:div))
as xs:string
{
  string-join(
    (api:external-uri($e),
      ($e/*[1] treat as element(xhtml:a)?)/@id[. ne 'chapter']),
    '#')
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
  if (not($is-async and $extra-boolean-attributes = 'open')) then ()
  else stp:error('BADOPTIONS', 'async and open are mutually exclusive'),
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
  case element(xhtml:div) return (
    switch($n/@class)
    case 'section' return toc:node(
      toc:id($n),
      (: ASSUMPTION Second element is a heading. :)
      $n/*[2],
      toc:guide-href($n),
      toc:guide($n/node()))
    default return ())
  default return ()
};

declare function toc:guide-node(
  $guide as element(guide),
  $is-duplicate as xs:boolean?,
  $is-closed as xs:boolean?)
as element(toc:node)
{
  toc:node(
    toc:id($guide),
    $guide/title treat as node(),
    api:external-uri($guide),
    (: If the guide node is closed, load async. Otherwise preload. :)
    $is-closed,
    'guide',
    (if ($is-duplicate) then 'duplicate' else (),
      if ($is-closed) then () else 'open',
      'sub-control', 'wrap-titles'),
    (: To preserve node order, use SMO rather than XPath. :)
    $guide/chapter-list/chapter
    ! toc:guide(doc(@href)/chapter/node()))
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
  ml:document-insert($location, element api:toc-uri { $uri })
};

(: Given node state, return appropriate HTML classnames. :)
declare function toc:render-node-class(
  $is-async as xs:boolean?,
  $is-open as xs:boolean?,
  $has-children as xs:boolean?,
  $has-following as xs:boolean?,
  $has-id as xs:boolean?,
  $wrap-titles as xs:boolean?)
as xs:string*
{
  if ($is-open) then 'collapsible'
  else if ($has-children) then 'expandable'
  else (),

  if ($has-following) then ()
  else if ($is-open) then 'lastCollapsible'
  else if ($has-children) then 'lastExpandable'
  else 'last',

  (: Include on nodes that will be loaded asynchronously. :)
  if (not($is-async)) then () else 'hasChildren',

  (: Include on nodes that have an @id
   : (used by list pages to identify the relevant TOC section)
   : but that aren't loaded asynchronously
   : because they're already loaded.
   :)
  if (not($has-id) or $is-async) then ()
  else ('loaded', 'initialized'),

  (: Mark asynchronous placeholder nodes for the treeview JavaScript. :)
  if (not($is-async)) then () else "async",
  (: Mark the nodes whose descendant titles should be wrapped :)
  if (not($wrap-titles)) then () else "wrapTitles"
};

(: Given a node, return appropriate HTML classnames. :)
declare function toc:render-node-class(
  $n as element(toc:node))
as xs:string*
{
  toc:render-node-class(
    xs:boolean($n/@async),
    xs:boolean($n/@open),
    exists($n/toc:node),
    exists($n/following-sibling::*),
    exists($n/@id),
    $n/@wrap-titles)
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

declare function toc:render-children-or-async(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $is-async as xs:boolean?,
  $children as element(toc:node)*)
{
  (: Placeholder for nodes to be loaded asynchronously. :)
  if ($is-async) then
    <li xmlns="http://www.w3.org/1999/xhtml">
      <span class="placeholder">&#160;</span>
    </li>
  else toc:render-node($uri, $prefix-for-hrefs, $children)
};

(: Given a node, render the children inline or as new documents. :)
declare function toc:render-node-children(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $is-open as xs:boolean?,
  $is-async as xs:boolean?,
  $children as element(toc:node)*)
as element()?
{
  if (not($stp:DEBUG)) then () else stp:fine(
    'toc:render-node-children',
    ($uri, $prefix-for-hrefs,
      count($children), xdmp:describe($children))),

  if (not($children)) then () else
  <ul xmlns="http://www.w3.org/1999/xhtml">
  {
    attribute style {
      'display:',
      if ($is-open) then 'block;' else 'none;' },
    toc:render-children-or-async(
      $uri, $prefix-for-hrefs, $is-async, $children)
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
    $n[@id]/attribute id { toc:node-id($n) },
    toc:render-node-hitarea($n),
    toc:render-node-link($prefix-for-hrefs, $n),
    toc:render-node-children(
      $uri, $prefix-for-hrefs,
      $n/@open/xs:boolean(.), $n/@async/xs:boolean(.),
      $n/toc:node)
  }
  </li>
};

declare function toc:render-node-tree(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $n as element(toc:node),
  $selected as xs:boolean)
as element()
{
  <ul xmlns="http://www.w3.org/1999/xhtml">
  {
    $n/@id,
    attribute style {
      'display:',
      if ($selected) then 'block;' else 'none;' },
    attribute class { 'treeview', 'apidoc_tree' },
    toc:render-node($uri, $prefix-for-hrefs, $n/toc:node)
  }
  </ul>
};

(: Given an async node, generate a new element with the correct base-uri. :)
declare function toc:render-async-node(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $n as element(toc:node))
as element()
{
  let $uri-new as xs:string := toc:uri(
    concat($uri, '/'),
    $n/@id/string() treat as xs:string,
    $n/@mode)
  let $_ := if (not($stp:DEBUG)) then () else stp:debug(
    'toc:render-async',
    ('async', 'mode', $n/@mode,
      $uri-new, xdmp:describe($n)))
  return <ul style="display: block;" xmlns="http://www.w3.org/1999/xhtml">
  {
    attribute xml:base { $uri-new },
    toc:render-node($uri, $prefix-for-hrefs, $n/toc:node)
  }
  </ul>
};

(: Given an async node, generate a new element with the correct base-uri. :)
declare function toc:render-async(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $list as element(toc:node)*)
as element()*
{
  let $m-seen := map:map()
  for $n in $list
  let $id as xs:string := $n/@id
  let $exists := map:contains($m-seen, $id)
  let $_ := map:put($m-seen, $id, true())
  where not($exists)
  return toc:render-async-node($uri, $prefix-for-hrefs, $n)
};

declare function toc:render-select-option(
  $n as element(toc:node),
  $selected as xs:boolean)
as element()
{
  <option xmlns="http://www.w3.org/1999/xhtml" class="toc_select_option">
  {
    (: JavaScript will decorate the parent select with an onchange handler.
     : Selecting any option will change the TOC display,
     : using this value to find the right top-level TOC entry.
     :)
    attribute value { $n/@id/string() treat as xs:string },
    if (not($selected)) then () else attribute selected { true() },
    $n/@display/string() treat as xs:string
  }
  </option>
};

declare function toc:render-content(
  $uri as xs:string,
  $prefix-for-hrefs as xs:string?,
  $toc as element(toc:root),
  $selected as element(toc:node)?)
as element()
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:render-content',
    ($uri, $prefix-for-hrefs, xdmp:describe($toc))),
  <div id="tocs_all" class="toc_section" xmlns="http://www.w3.org/1999/xhtml">
    <div class="toc_select">
      Section: <select id="toc_select">
  {
    (: To preserve node order, use SMO rather than XPath. :)
    $toc/toc:node
    ! toc:render-select-option(., . is $selected)
  }
      </select>
    </div>
    <div class="scrollable_section">
      <input id="config-filter" name="config-filter" class="config-filter"/>
      <img src="/apidoc/images/removeFilter.png" id="config-filter-close-button"
  class="config-filter-close-button"/>
      <div id="treeglobal" class="treecontrol top_control global_control">
        <span class="expand" title="Expand the entire tree below">
          <img id="treeglobalimage" src="/css/apidoc/images/plus.gif"></img>
          <span id="treeglobaltext">expand</span>
        </span>
      </div>
      <div id="apidoc_tree_container" class="pjax_enabled">
  {
    (: To preserve node order, use SMO rather than XPath. :)
    $toc/toc:node
    ! toc:render-node-tree(
      $uri, $prefix-for-hrefs, ., . is $selected)
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
  $version as xs:string,
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
   : We do not filter out duplicates here,
   : because the async state of the original may differ.
   :)
  toc:render-async(
    $uri, $prefix-for-hrefs, $toc//toc:node[@async/xs:boolean(.)]),

  (: Wrapper includes placeholder elements for use by toc_filter.js toc_init.
   : Could some of this chrome move into page rendering?
   :)
  <div id="all_tocs" xml:base="{ $uri }"
       xmlns="http://www.w3.org/1999/xhtml">
    <div id="toc" class="toc">
      <div id="toc_content">
  {
    toc:render-content(
      $uri, $prefix-for-hrefs, $toc,
      (: First node always starts selected. :)
      $toc/toc:node[1])
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
  $version as xs:string,
  $uri as xs:string,
  $is-default as xs:boolean)
as empty-sequence()
{
  (: Every result element must set its own base-uri,
   : so we known where to store it in the database.
   :)
  let $uri-toc-root := toc:root-uri($version)
  let $_ := if (not($stp:DEBUG)) then () else stp:debug(
    'toc:render', ($version, $is-default, $uri-toc-root, '=>', $uri))
  let $m-seen := map:map()
  for $n in toc:render(
    $version, $uri,
    if ($is-default) then () else concat("/", $version),
    doc($uri-toc-root)/* treat as element())
  (: Force an error if the base-uri was not set. :)
  let $uri-new as xs:anyURI := base-uri($n)
  order by $uri-new
  return (
    if (not($stp:DEBUG)) then () else stp:debug(
      'toc:render', ('inserting', $uri-new)),
    if (map:get($m-seen, $uri-new)) then stp:error('CONFLICT', $uri-new)
    else map:put($m-seen, $uri-new, $uri-new),
    ml:document-insert($uri-new, $n))
};

declare function toc:render(
  $version as xs:string)
as empty-sequence()
{
  (: Save the location of the new HTML TOC root to the database. :)
  ml:document-insert(
    api:toc-uri-location($version),
    text { toc:html-uri($version) }),
  (: Render and insert the new HTML TOC root. :)
  toc:render($version, toc:html-uri($version), false()),

  (: If we are processing the default version,
   : then we need to render another copy of the TOC
   : that does not include version numbers in its href links.
   : Similar to above, except that the URI uses 'default' not $version.
   :)
  if (not($version eq $api:DEFAULT-VERSION)) then () else (
    ml:document-insert(
      $api:TOC-URI-DEFAULT,
      text { toc:html-uri('default') }),
    toc:render($version, toc:html-uri('default'), true()))
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
  $version-number as xs:double,
  $xsd-docs as document-node()*,
  $e as element())
as xs:string*
{
  (: For each of the other applicable elements in the same namespace :)
  let $ns := namespace-uri($e)
  for $other in root($e)//*[namespace-uri(.) eq $ns][not(. is $e)][
    not(@added-in) or @added-in le $version-number]
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
  $version as xs:string,
  $mode as xs:string,
  $lib as xs:string?)
as xs:integer
{
  xdmp:estimate(
    cts:search(
      collection(),
      cts:and-query(
        (cts:directory-query(api:version-dir($version), "1"),
          cts:element-attribute-value-query(
            xs:QName('api:function-page'),
            xs:QName('mode'),
            $mode),
          if (not($lib)) then ()
          else cts:or-query((
            cts:element-attribute-value-query(
               xs:QName('api:function'), xs:QName('lib'), $lib),
            cts:element-attribute-value-query(
               xs:QName('api:function'), xs:QName('object'), $lib))))
      )
     )
   )
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
  if (not($stp:DEBUG)) then ()
  else
    stp:fine(
      'toc:category-href:',
      (
        'category', $category,
        'subcat', $subcategory,
        'is-exhaustive', $is-exhaustive,
        'use-category', $use-category,
        'mode', $mode,
        'one-subcat', xdmp:describe($one-subcategory-lib),
        'main-subcat', xdmp:describe($main-subcategory-lib)
      )
    ),
  (: The initial empty string ensures a leading '/'. :)
  string-join(
    ('',
      switch($mode)
      case $api:MODE-JAVASCRIPT return 'js'
      default return (),
      (:
       : On the one hand, I hate myself for writing a special case for the
       : Search library. On the other hand, I've spent enough time trying to
       : coax a non-duplicating URL out of this code. The problem is that the
       : word "search" just shows up in too many parts of our API. This
       : function was generating the URL "/search" for both the Search Builtins
       : and the Search API Library. I'm moving on. -- Dave Cassel.
       :)
      if ($category eq "Search") then
        $one-subcategory-lib || "-library"
      else if ($is-exhaustive) then ($one-subcategory-lib treat as item())
      (: Include category in path - eg usually for REST :)
      else if ($use-category) then (
        $one-subcategory-lib treat as item(),
        toc:path-for-category($category),
        toc:path-for-category($subcategory))
      else (
        (: This may be empty. :)
        $main-subcategory-lib,
        toc:path-for-category($subcategory))),
    '/')
};

declare function toc:function-name-nodes(
  $functions as element(api:function)*)
as element(api:function-name)*
{
  (: NOTE: These elements are intentionally siblings, not parentless,
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
  (:
   : There is a hack that puts a blank function in the
   : xquery module bucket for some prefixes.
   : This is because these libraries include both built-in and library functions.
   : This affects semantics and temporal.
   :
   : These are easily detected by looking for names
   : that end with a function delimiter.
   :)
  return $wrapper/api:function-name[not(matches(., '[:\.]$'))]
};

declare function toc:function-node(
  $version as xs:string,
  $function-name as element(api:function-name))
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
    (: By now the JavaScript translation should already have happened. :)
    case $api:MODE-REST return api:reverse-translate-REST-resource-name(
      (: For 5.0 hide the verb. :)
      if (xs:double($version) gt 5.0) then $function-name
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
  $version as xs:string,
  $functions as element(api:function)*)
as element(toc:node)*
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:function-nodes',
    (xdmp:describe($functions), $version)),
  toc:function-node($version, toc:function-name-nodes($functions))
};

declare function toc:render-summary(
  $version as xs:string,
  $mode as xs:string,
  $summary as element(apidoc:summary))
as element()
{
  (: Wrap summary content with <p> if not already present.
   : The wrapper might be in several namespaces.
   :)
  stp:fixup($version, $summary, ($mode, 'toc'))
  ! (if (not($summary[not(xhtml:p|apidoc:p|p)])) then .
    else <p xmlns="http://www.w3.org/1999/xhtml">{ . }</p>)
};

declare function toc:functions-by-category-subcat-node(
  $version as xs:string,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $prefixes-not-builtin as xs:string*,
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
    else ($in-this-subcategory/(@lib | @object)
        [not(. eq $main-subcategory-lib)])[1])
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
      else toc:display-suffix($one-subcategory-lib, $mode)),
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
          $version, $mode,
          toc:get-summary-for-category(
            $version, $mode, $prefixes-not-builtin,
            $cat, $subcat, $main-subcategory-lib)) },
      (: function TOC node :)
      toc:function-nodes($version, $in-this-subcategory)))
};

declare function toc:functions-by-category-subcat(
  $version as xs:string,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $prefixes-not-builtin as xs:string*,
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
    $version, $mode, $m-mode-functions,
    $prefixes-not-builtin, $cat, $is-REST,
    $single-lib-for-category, $subcat, $in-this-subcategory)
};

(: TODO refactor. :)
declare function toc:functions-by-category(
  $version as xs:string,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $prefixes-not-builtin as xs:string*,
  $bucket-id as xs:string,
  $cat as xs:string,
  $is-REST as xs:boolean,
  $in-this-category as element(api:function)+)
as element(toc:node)+
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:functions-by-category', ($version, $mode)),
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
    toc:category-href(
      $cat, $cat, $is-exhaustive,
      false(), $mode,
      if ($is-exhaustive) then $single-lib-for-category else (),
      if ($is-exhaustive) then () else $single-lib-for-category))
  return toc:node(
    $bucket-id||'_'||translate(
        translate(translate($cat, ' ' , ''), '(', ''), ')', ''),
    toc:display-category($cat)
      || toc:display-suffix($single-lib-for-category, $mode),
    $href,
    (), (), ('function-list-page'),
    (
      attribute mode { $mode },

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
            $version, $mode,
            toc:get-summary-for-category(
              $version, $mode, $prefixes-not-builtin,
              $cat, (), $single-lib-for-category))
        }
      ),

      (: ASSUMPTION
       : A category has either functions as children or sub-categories,
       : never both.
       :)
      (: Are these function TOC nodes? :)
      if (not($sub-categories)) then toc:function-nodes(
        $version, $in-this-category)
      else toc:functions-by-category-subcat(
        $version, $mode, $m-mode-functions,
        $prefixes-not-builtin, $cat, $is-REST,
        $in-this-category, $single-lib-for-category, $sub-categories)
    )
  )
};

(: Build toc nodes for functions by category.
 :)
declare function toc:functions-by-bucket(
  $version as xs:string,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $prefixes-not-builtin as xs:string*)
as element(toc:node)+
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:functions-by-bucket',
    ($version, $mode,
      map:count($m-mode-functions),
      map:count(map:get($m-mode-functions, $MAP-KEY-BUCKET)))),
  (: TODO Move this into configuration. :)
  let $forced-order := (
    'MarkLogic Built-In Functions',
    'XQuery Library Modules', 'CPF Functions',
    'W3C-Standard Functions', 'REST Resources API')
  let $m-buckets as map:map := map:get($m-mode-functions, $MAP-KEY-BUCKET)
  for $b in map:keys($m-buckets)
  (: bucket node
   : ID for function buckets is the display name minus spaces.
   : async is ignored for REST, because we ignore this toc:node.
   :)
  let $bucket-id := (
    if ($mode eq $api:MODE-JAVASCRIPT) then 'js_'
    else '')||translate(
      translate(translate($b, ' ', ''), '(', ''), ')', '')
  let $is-REST := $mode eq $api:MODE-REST
  order by index-of($forced-order, $b) ascending, $b
  return toc:node(
    $bucket-id, $b, (),
    false(), (), ('open', 'sub-control'),
    (attribute mode { $mode },
      let $m-cats := map:get($m-buckets, $b)
      for $cat in map:keys($m-cats)
      order by $cat
      return toc:functions-by-category(
        $version, $mode, $m-mode-functions,
        $prefixes-not-builtin,
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
    else if ($e/@auto-exclude) then toc:help-auto-exclude(
      $version-number, $xsd-docs, $e)
    else ())
  let $help-content := element api:help-node {
    toc:help-render(
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

(: This ignores sections that were added in a later server version,
 : yielding an empty sequence.
 :)
declare function toc:help-content(
  $version-number as xs:double,
  $xsd-docs as document-node()*,
  $e as element())
as node()*
{
  if ($version-number lt $e/@added-in) then () else
  typeswitch($e)
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
      element toc:content { attribute auto-help-list { true() } },
      toc:help-content($version-number, $xsd-docs, $help/*)))
};

(:
 : This creates an XML TOC section for a library, with an id.
 : The api:lib elements are generated in api:get-libs.
 : This is javascript-aware.
 :)
declare function toc:api-lib(
  $version as xs:string,
  $mode as xs:string,
  $m-mode-functions as map:map,
  $by-bucket as element(toc:node)+,
  $lib as element(api:lib),
  $function-count as xs:integer)
as element(toc:node)
{
  toc:node(
    concat($lib, '_', toc:id($lib)),
    concat(
      toc:prefix-for-lib($lib),
      if ($mode eq $api:MODE-JAVASCRIPT) then '.' else ':'),
    concat(
      if ($mode eq $api:MODE-JAVASCRIPT) then '/js/' else '/',
      $lib),
    true(), (), ('function-list-page', 'footnote'[$lib/@built-in]),
    ($lib/@category-bucket,
      attribute function-count { $function-count },
      attribute namespace { api:namespace($lib)/@uri },
      attribute mode { $mode },

      element toc:title {
        toc:prefix-for-lib($lib), 'functions' },
      element toc:intro {
        <p xmlns="http://www.w3.org/1999/xhtml">
        The table below lists all the
        {
          toc:prefix-for-lib($lib),
          if ($lib/@built-in) then 'built-in' else 'XQuery library'
        }
        functions (in this namespace:
          <code>{ api:namespace($lib)/@uri/string() }</code>).
        </p>,
        (: TODO Right now this really wants toc:nodes not functions. :)
        toc:lib-sub-pages($mode, $m-mode-functions, $by-bucket, $lib),
        (: Summary may be empty. :)
        toc:get-summary-for-lib(
          $version, $lib)/toc:render-summary($version, $mode, .),
        api:namespace($lib)/summary-addendum/node()
      },
      comment { 'Current lib:', $lib },
      toc:function-nodes(
        $version,
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

declare function toc:libs-for-mode(
  $version as xs:string,
  $mode as xs:string)
as element(api:lib)*
{
  switch($mode)
  case $api:MODE-JAVASCRIPT return api:libs-all($version, $mode)
  case $api:MODE-XPATH return api:libs-all($version, $mode)
  case $api:MODE-REST return ()
  default return stp:error('UNEXPECTED', $mode)
};

(: Convenience constructor for a toc:node
 : based on a document-list entry.
 :)
declare function toc:entry-to-node(
  $entry as element(apidoc:entry),
  $id as xs:string,
  $title as xs:string,
  $is-closed as xs:boolean?,
  $body as item()*)
as element(toc:node)
{
  if (not($stp:DEBUG)) then () else stp:debug(
    'toc:entry-to-node#4',
    (xdmp:describe($entry), 'id', $id, 'title', $title,
      'body', xdmp:describe($body))),
  toc:node(
    $id,
    $title,
    $entry/@href,
    $entry/@async/xs:boolean(.),
    $entry/@type,
    (if ($is-closed) then () else 'open',
      (: Transform any of these attributes to toc:node attributes.
       : Extend as needed.
       :)
      $entry/(@TBD)[xs:boolean(.)]/local-name(.)),
    ($entry/@mode,
      $body))
};

(: Convenience constructor for a toc:node
 : based on a document-list entry.
 :)
declare function toc:entry-to-node(
  $entry as element(apidoc:entry),
  $id as xs:string,
  $title as xs:string,
  $body as item()*)
as element(toc:node)
{
  toc:entry-to-node(
    $entry, $id, $title,
    xs:boolean($entry/@toc-closed), $body)
};

(: Convenience constructor for a toc:node
 : based on a document-list entry.
 :)
declare function toc:entry-to-node(
  $entry as element(apidoc:entry),
  $body as item()*)
as element(toc:node)
{
  toc:entry-to-node(
    $entry,
    if ($entry/@id) then $entry/@id else toc:id($entry),
    ($entry/@toc-title, $entry/@title)[1] treat as item(),
    $body)
};

(: Transform a document-list entry element
 : for a function-reference to a toc:node.
 :)
declare function toc:function-reference-node(
  $version as xs:string,
  $m-functions as map:map,
  $entry as element(apidoc:entry))
as element(toc:node)+
{
  (: A function-reference entry may not have any entry children.
   : Any @id will be ignored.
   : Construct the body directly.
   : We may want a flat list, and we always want a list by category.
   :)
  let $mode as xs:string := $entry/@mode
  (: For MODE-REST there will be no libs nor prefixes. :)
  let $mode-libs := toc:libs-for-mode($version, $mode)
  let $prefixes-not-builtin as xs:string* := $mode-libs[not(@built-in)]
  let $m-mode-functions := map:get($m-functions, $mode)
  let $m-mode-categories as element(toc:node)+ := toc:functions-by-bucket(
    $version, $mode, $m-mode-functions, $prefixes-not-builtin)
  let $function-count := string(toc:function-count($version, $mode, ()))
  let $title as xs:string := replace(
    ($entry/@toc-title, $entry/@title)[1], '%d', $function-count)
  let $all-functions := $entry/@all-functions/xs:boolean(.)
  let $title-all-functions := (
    if (not($all-functions)) then ()
    else replace($entry/@all-functions-title, '%d', $function-count))
  return (
    toc:entry-to-node(
      $entry,
      'AllFunctionsByCat-'||$mode,
      $title,
      (element toc:title { $title },
        element toc:intro { $entry/apidoc:intro/node() },
        $m-mode-categories)),

    if (not($all-functions)) then () else toc:entry-to-node(
      $entry,
      'AllFunctions.'||$mode,
      $title-all-functions,
      xs:boolean($entry/@all-functions-toc-closed),
      (element toc:title { $title-all-functions },
        element toc:intro { $entry/apidoc:intro/node() },
        let $m-seen := map:map()
        for $lib in ($mode-libs treat as element()+)
        (: Skip duplicates per #246. This affects "sem:". :)
        let $is-duplicate := map:contains($m-seen, $lib)
        let $_ := if ($is-duplicate) then () else map:put($m-seen, $lib, 1)
        let $count := toc:function-count($version, $mode, $lib)
        where $count and not($is-duplicate)
        order by $lib
        return toc:api-lib(
          $version, $mode, $m-mode-functions,
          $m-mode-categories, $lib, $count))))
};

(: Transform a document-list entry element to a toc:node.
 : Some entry types can return multiple nodes.
 : Some entry types are ignored.
 :)
declare function toc:entry-node(
  $version as xs:string,
  $xsd-docs as document-node()*,
  $m-functions as map:map,
  $guide-docs as element(guide)+,
  $help-config as element(help),
  $entry as element(apidoc:entry))
as element(toc:node)*
{
  let $type as xs:string? := $entry/@type
  let $_ := if (not($stp:DEBUG)) then () else stp:debug(
    'toc:entry-node#6',
    ($version, xdmp:describe($entry), 'type', xdmp:describe($type)))
  return switch($type)
  case 'download' return ()
  case 'external' return toc:node-external(
    ($entry/@toc-title, $entry/@title)[1], $entry/@href)
  case 'function-reference' return toc:function-reference-node(
    $version, $m-functions, $entry)
  case 'help' return toc:help(
    number($version), $xsd-docs, $help-config)
  (: At the moment an entry with no @type is always
   : a wrapper for guide elements.
   : For each guide child, find the right guide node
   : and build its toc node.
   :)
  case () return toc:entry-to-node(
    $entry,
    (: To preserve node order, use SMO rather than XPath. :)
    $entry/* ! (
      typeswitch(.)
      case element(apidoc:entry) return toc:entry-node(
        $version, $xsd-docs, $m-functions,
        $guide-docs, $help-config, .)
      case element(apidoc:guide) return (
        let $name as xs:string := @url-name
        let $match as element()? := $guide-docs[
          ends-with(base-uri(.), '/'||$name||'.xml')]
        let $_ := if ($match) then () else stp:error('NOGUIDE', $name)
        return toc:guide-node(
          $match, @duplicate/xs:boolean(.), @toc-closed/xs:boolean(.)))
      default return stp:error(
        'UNEXPECTED',
        ('no handler for child element',
          xdmp:key-from-QName(node-name($entry)),
          xdmp:describe($entry)))))
  default return stp:error(
    'UNEXPECTED', ('no handler for type', xdmp:describe($type)))
};

(: Transform a document-list group element to a toc:node. :)
declare function toc:group-node(
  $version as xs:string,
  $xsd-docs as document-node()*,
  $m-functions as map:map,
  $guide-docs as element(guide)+,
  $help-config as element(help),
  $group as element(apidoc:group))
as element(toc:node)
{
  toc:node(
    if ($group/@id) then $group/@id else toc:id($group),
    ($group/@toc-title, $group/@title)[1],
    $group/@href,
    (: Group nodes are always open, so they can never be async. :)
    false(),
    $group/@type,
    ('group',
      (: Transform any of these attributes to toc:node attributes.
       : Extend as needed.
       :)
      $group/(@TBD)[xs:boolean(.)]/local-name(.)),
    ($group/@mode,
      (: Handle entries. :)
      toc:entry-node(
        $version, $xsd-docs, $m-functions,
        $guide-docs, $help-config, $group/apidoc:entry)))
};

declare function toc:create(
  $version as xs:string,
  $xsd-docs as document-node()*)
as element(toc:root)
{
  let $document-list as element(apidoc:docs) := api:document-list($version)
  (: Build expensive data structures up front. :)
  let $m-functions := toc:functions-map($version)
  (: These are consolidated guides. :)
  let $guide-docs as element(guide)+ := xdmp:directory(
    concat(api:version-dir($version), 'guide/'))/guide
  let $help-config as element(help) := u:get-doc(
    '/apidoc/config/help-config.xml')/help

  (: Detect any guides that would not be displayed,
   : or would be displayed too many times.
   :)
  let $_ := (
    for $uri in $guide-docs/base-uri(.)
    let $id as xs:string := replace($uri, '^.+/([^/]+)\.xml$', '$1')
    let $matches := $document-list//apidoc:guide[
      not(@duplicate/xs:boolean(.))][
      @url-name eq $id]
    let $_ := if (not($stp:DEBUG)) then () else stp:debug(
      'toc:create', ('checking', $uri, $id, xdmp:describe($matches)))
    where not($matches instance of item())
    return (
      if (not($matches)) then stp:error(
        'NOGUIDE', ('No document-list guide element found for', $id))
      else stp:error(
        'TOOMANYGUIDES',
        ('Guide', $id, 'appears more than once without @duplicate set',
          xdmp:describe($matches)))))

  return element toc:root {
    attribute display {
      ($document-list/@toc-title, $document-list/@title)[1]/string()
      treat as xs:string },
    attribute open { true() },
    toc:group-node(
      $version, $xsd-docs, $m-functions,
      $guide-docs, $help-config, $document-list/apidoc:group) }
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
  $xsd-path as xs:string,
  $uri as xs:string)
as empty-sequence()
{
  stp:info('toc:toc', ("Creating new TOC at", $uri)),
  ml:document-insert(
    $uri,
    toc:create($version, toc:xsd-docs($xsd-path))),
  stp:info('toc:toc', xdmp:elapsed-time())
};

declare function toc:toc(
  $version as xs:string,
  $xsd-path as xs:string)
as empty-sequence()
{
  toc:toc($version, $xsd-path, toc:root-uri($version))
};

(: #436
 : The help page code relies on undocumented and unsupported functions
 : found in the MarkLogic admin UI code at admin-forms.xqy.
 : The location of this library module differs from ML7 to ML8,
 : so an import will not work.
 :)

(: Display Help Text on Help Pages
::
:: $schemaroot is the root element of the schema file to pass in
:: $name is the element name in the schema that contains admin:help nodes
:: $multiple-uses specifies which admin:help element has the info you need
::                for this help page (in document order)
:: $excluded specifies a list of the complex element fields to exclude
:: $line-after specifies element fields to palce an hr line after.  This is
::             not really needed anymore as there is now code to look for the
::             admin:hr, but it is still there in case you want to add a line
::             somewhere where there is no admin:hr.
:: $print-buttons specifies whether to print out the buttons and tabs
::                section--pass in fn:true() for yes, fn:false() for no.
::
:)

declare function toc:help-render(
  $schemaroot as node(),
  $name as xs:string,
  $multiple-uses as xs:integer,
  $excluded as xs:string*,
  $line-after as xs:string*,
  $print-buttons as xs:boolean)
as node()*
{
  let $decl    := $schemaroot/xs:element[@name eq $name],
      $typ     := local-name-from-QName($decl/@type),
      $complex := $schemaroot/xs:complexType[@name eq $typ]
  return (
    $schemaroot/xs:element[@name eq $name]/xs:annotation/xs:appinfo/
                          admin:help[$multiple-uses]/node()
    ,
    <ul>
      {
        for $elname in $complex/(xs:all | xs:sequence)//xs:element
        (: Filter out anything that is hidden or has no help element.
         : The value of @ref is a QName, but we can only do string comparison.
         :)
        let $ref as xs:string := $elname/@ref/string()
        let $n := ($schemaroot/xs:element[@name eq $ref])[1]
        where (fn:not($n/xs:annotation/xs:appinfo/admin:hidden)
          and $n/xs:annotation/xs:appinfo/admin:help
          and fn:not($n/@name = $excluded))
        return
          (: special cases for role-ids and uri (collections page) :)
          if ( fn:string($elname/@ref) = ("role-ids", "uri" ) )
            then (
              if ( $name = ("role", "collection") )
              (: special case for role because it used diferently in user and role :)
                  then ( for $helpnode in $schemaroot/xs:element[@name eq
                                    fn:string($elname/@ref)]/xs:annotation/xs:appinfo
                                                            /admin:help
                        return
                        <li>{ $helpnode/node()}</li> )
                  else ( <li>{ $schemaroot/xs:element[@name eq
                                  fn:string($elname/@ref)]/xs:annotation/xs:appinfo
                                                          /admin:help[1]/node() }</li> )
                  )
          else if ( fn:string($elname/@ref) eq "root")
            then
              <li>
                {
                  if ($name eq "xdbc-server" or $name eq "odbc-server") then
                    $schemaroot/xs:element[@name eq fn:string($elname/@ref)]
                          /xs:annotation/xs:appinfo
                          /admin:help[2]/node()
                  else
                    $schemaroot/xs:element[@name eq fn:string($elname/@ref)]
                          /xs:annotation/xs:appinfo
                          /admin:help[1]/node()
                }
              </li>
          else (
            <li>
              {
                if ($n/xs:annotation/xs:appinfo/admin:help[$multiple-uses]/node())
                   then $n/xs:annotation/xs:appinfo/admin:help[$multiple-uses]/node()
                (: take the first node if there are not multiple ones :)
                else $n/xs:annotation/xs:appinfo/admin:help[1]/node()
              }
            </li>
            ,
            if ( ( fn:local-name-from-QName($elname/@ref) = $line-after ) or
                   $n/xs:annotation/xs:appinfo/admin:hr )
            then ( <hr class="control-line" size="1"/>, <br /> )
            else ( )
          )
      }
    </ul>
    ,
    (: only print the buttons and tabs section if $print-buttons is true :)
    if ( $print-buttons )
      then (
      (: if there is more then one help element, assume the last one describes the
        buttons and tabs and put it on the end.  If there are multiple-uses,
        put the buttons and tabs at the position last() - (multiple-uses -1),
        which is the reverse of the position for the opening content.  :)
        if ( fn:count( $schemaroot/xs:element[@name eq $name]/xs:annotation/xs:appinfo
                            /admin:help ) > 1 )
          then (
          $schemaroot/xs:element[@name eq $name]/xs:annotation/xs:appinfo/
                        admin:help[last() - ($multiple-uses - 1) ]/node() )
        else ()
      )
    else ()
  )
};

(: apidoc/setup/toc.xqm :)
