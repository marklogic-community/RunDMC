xquery version "1.0-ml";
(: Test module for apidoc/setup/toc.xqm
 :
 : Note that all toc:render test cases must handle both
 : document and element results.
 :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "/apidoc/setup/setup.xqm";
import module namespace toc="http://marklogic.com/rundmc/api/toc"
  at "/apidoc/setup/toc.xqm";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc" ;
declare namespace xh="http://www.w3.org/1999/xhtml" ;

declare variable $VERSION := '8.0' ;

declare %t:case function t:category-href-xquery()
{
  toc:category-href(
    'Library Services', 'Library Services',
    true(), false(),
    $api:MODE-XPATH, 'dls', '')
  ! at:equal(., '/dls')
};

declare %t:case function t:guide-toc-closed()
{
  toc:entry-node(
    $VERSION, (), map:map(),
    element guide {
      attribute xml:base { '/test.xml' },
      element title { 'test' } },
    element help { () },
    element apidoc:entry {
      attribute title { 'test' },
      element apidoc:guide {
        attribute url-name { 'test' },
        attribute toc-closed { true() } } })
  ! at:empty(toc:node/@open/xs:boolean(.))
};

declare %t:case function t:guide-toc-open()
{
  toc:entry-node(
    $VERSION, (), map:map(),
    element guide {
      attribute xml:base { '/test.xml' },
      element title { 'test' } },
    element help { () },
    element apidoc:entry {
      attribute title { 'test' },
      element apidoc:guide {
        attribute url-name { 'test' } } })
  ! at:equal(
    toc:node/@open/xs:boolean(.),
    true())
};

declare %t:case function t:display-suffix-javascript()
{
  toc:display-suffix('xdmp', $api:MODE-JAVASCRIPT)
  ! at:equal(., ' (xdmp.)')
};

declare %t:case function t:display-suffix-xpath()
{
  toc:display-suffix('xdmp', $api:MODE-XPATH)
  ! at:equal(., ' (xdmp:)')
};

declare %t:case function t:render-0-empty()
{
  <root display="All Documentation"
  xmlns="http://marklogic.com/rundmc/api/toc"/>
  !
  at:equal(
    toc:render($VERSION, 'toc-test', '/3.14', .)
    (: Handle xml:base attribute :)
    ! element { node-name(.) } {
      @* except @xml:base,
      node() }
    ,

<div id="all_tocs" xmlns="http://www.w3.org/1999/xhtml"><div id="toc" class="toc"><div id="toc_content"><div id="tocs_all" class="toc_section"><div class="toc_select">
      Section: <select id="toc_select"></select></div><div class="scrollable_section"><input id="config-filter" name="config-filter" class="config-filter"/><img src="/apidoc/images/removeFilter.png" id="config-filter-close-button" class="config-filter-close-button"/><div id="treeglobal" class="treecontrol top_control global_control"><span class="expand" title="Expand the entire tree below"><img id="treeglobalimage" src="/css/apidoc/images/plus.gif"/><span id="treeglobaltext">expand</span></span></div><div id="apidoc_tree_container" class="pjax_enabled"></div></div></div></div><div id="splitter"></div></div><div id="tocPartsDir" style="display:none;">toc-test/</div></div>

  )
};

declare %t:case function t:render-1-simple()
{
  <root display="All Documentation"
  open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node id="n1" display="node 1" open="true"></node>
    <node id="n2" display="node 2" open="true"></node>
    <node id="n3" display="node 3" open="true"></node>
  </root>
  ! at:equal(
    toc:render($VERSION, 'toc-test', '/3.14', .)
    (: Handle xml:base attribute :)
    ! element { node-name(.) } {
      @* except @xml:base,
      node() }
    ,

<div id="all_tocs" xmlns="http://www.w3.org/1999/xhtml"><div id="toc" class="toc"><div id="toc_content"><div id="tocs_all" class="toc_section"><div class="toc_select">
      Section: <select id="toc_select">
            <option class="toc_select_option" value="n1" selected="true">node 1</option>
            <option class="toc_select_option" value="n2">node 2</option>
            <option class="toc_select_option" value="n3">node 3</option>
          </select></div><div class="scrollable_section"><input id="config-filter" name="config-filter" class="config-filter"/><img src="/apidoc/images/removeFilter.png" id="config-filter-close-button" class="config-filter-close-button"/><div id="treeglobal" class="treecontrol top_control global_control"><span class="expand" title="Expand the entire tree below"><img id="treeglobalimage" src="/css/apidoc/images/plus.gif"/><span id="treeglobaltext">expand</span></span></div><div id="apidoc_tree_container" class="pjax_enabled"><ul id="n1" style="display: block;" class="treeview apidoc_tree"></ul><ul id="n2" style="display: none;" class="treeview apidoc_tree"></ul><ul id="n3" style="display: none;" class="treeview apidoc_tree"></ul></div></div></div></div><div id="splitter"></div></div><div id="tocPartsDir" style="display:none;">toc-test/</div></div>

  )
};

declare %t:case function t:render-1-simple-href()
{
  <root display="All Documentation"
  open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node id="n1" display="node 1" href="/node/1"></node>
    <node id="n2" display="node 2" open="true"></node>
    <node id="n3" display="node 3" open="true"></node>
  </root>
  ! at:empty(
    toc:render($VERSION, 'toc-test', '/3.14', .)
    //xh:a[@href])
};

declare %t:case function t:render-1-simple-uri()
{
  <root display="All Documentation"
  open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node id="n1" display="node 1" open="true"></node>
    <node id="n2" display="node 2" open="true"></node>
    <node id="n3" display="node 3" open="true"></node>
  </root>
  ! at:equal(
    toc:render($VERSION, 'toc-test', '/3.14', .)
    ! base-uri(.),
    'toc-test')
};

declare %t:case function t:render-async-2-content()
{
  <root display="All Documentation"
    open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node id="n1" display="node 1" href="/node/1"></node>
    <node id="node-2" display="node 2" async="true">
      <node id="n1_1" display="node 2.1"></node>
      <node id="n1_2" display="node 2.2"></node>
    </node>
  </root>
  ! at:equal(
    toc:render($VERSION, 'toc-test', '/3.14', .)
    (: Handle xml:base attribute :)
    ! element { node-name(.) } {
      @* except @xml:base,
      node() }
    /self::xh:ul
    ,
    <ul style="display: block;" xmlns="http://www.w3.org/1999/xhtml">
      <li class="loaded initialized" id="n1_1"><span>node 2.1</span></li>
      <li class="last loaded initialized" id="n1_2"><span>node 2.2</span></li>
    </ul>
  )
};

declare %t:case function t:render-async-2-placeholder()
{
  <root display="All Documentation"
    open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node id="n1" display="node 1" href="/node/1"></node>
    <node id="node-2" display="node 2" async="true">
      <node id="n1_1" display="node 2.1"></node>
      <node id="n1_2" display="node 2.2"></node>
    </node>
  </root>
  ! at:equal(
    toc:render($VERSION, 'toc-test', '/3.14', .)[
      base-uri(.) eq 'toc-test']
    //xh:ul[@id eq 'node-2']
    ,

<ul id="node-2" style="display: none;" class="treeview apidoc_tree" xmlns="http://www.w3.org/1999/xhtml">
  <li class="loaded initialized" id="n1_1"><span>node 2.1</span></li>
  <li class="last loaded initialized" id="n1_2"><span>node 2.2</span></li>
</ul>

  )
};

declare %t:case function t:render-2-async-uris()
{
  <root display="All Documentation"
    open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node id="n1" display="node 1" href="/node/1"></node>
    <node id="n2" display="node 2" async="true">
      <node id="n1_1" display="node 2.1"></node>
      <node id="n1_2" display="node 2.2"></node>
    </node>
  </root>
  ! at:equal(
    toc:render($VERSION, 'toc-test', '/3.14', .)
    ! base-uri(.),
    ('toc-test/n2.html', 'toc-test'))
};

declare %t:case function t:render-2-async-xdmp()
{
  <root display="All Documentation"
    open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node id="n1" display="node 1" href="/node/1">
      <node id="xdmp_n9b9475fceb6b577b"
  href="/js/xdmp" display="xdmp." function-count="337"
  namespace="http://marklogic.com/xdmp"
  category-bucket="MarkLogic Built-In Functions"
  function-list-page="true" async="true"
  mode="{ $api:MODE-JAVASCRIPT }" footnote="true"
  xmlns="http://marklogic.com/rundmc/api/toc">
        <node id="n1_1_1" display="node 2.1"></node>
        <node id="n1_1_2" display="node 2.2"></node>
      </node>
    </node>
  </root>
  ! at:equal(
    toc:render($VERSION, 'toc-test', '/3.14', .)
    //xh:div[@id = 'apidoc_tree_container']
,

  <div id="apidoc_tree_container" class="pjax_enabled" xmlns="http://www.w3.org/1999/xhtml"><ul id="n1" style="display: block;" class="treeview apidoc_tree">
    <li class="expandable lastExpandable hasChildren async" id="js_xdmp_n9b9475fceb6b577b"><div class="hitarea expandable-hitarea lastExpandable-hitarea"></div><a href="/3.14/js/xdmp" title="http://marklogic.com/xdmp">xdmp.<span class="function_count"> (337)</span></a><ul style="display: none;">
        <li><span class="placeholder">&#160;</span></li>
      </ul></li>
  </ul></div>

  )
};

(: test/apidoc-toc.xqm :)