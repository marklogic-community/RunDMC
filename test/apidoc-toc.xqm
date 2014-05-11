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

declare namespace xh="http://www.w3.org/1999/xhtml" ;

declare %t:case function t:render-0-empty()
{
  <root display="All Documentation"
  xmlns="http://marklogic.com/rundmc/api/toc"/>
  !
  at:equal(
    toc:render('toc-test', '/3.14', .)
    (: Handle xml:base attribute :)
    ! element { node-name(.) } {
      @* except @xml:base,
      node() }
    ,
    <div id="all_tocs" xmlns="http://www.w3.org/1999/xhtml">
      <div id="toc" class="toc">
        <div id="toc_content">
          <div id="tocs-all" class="toc_section">
            <div class="scrollable_section">
              <input id="config-filter" name="config-filter" class="config-filter"/>
              <img src="/apidoc/images/removeFilter.png" id="config-filter-close-button" class="config-filter-close-button"/>
              <div id="apidoc_tree_container" class="pjax_enabled">
                <ul id="apidoc_tree" class="treeview">
                  <li id="AllDocumentation" class="collapsible lastCollapsible">
                    <div class="hitarea collapsible-hitarea lastCollapsible-hitarea"></div>
                    <a href="/3.14/" class="toc_root">All Documentation</a>
                    <ul></ul>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
        <div id="splitter"></div>
      </div>
      <div id="tocPartsDir" style="display:none;">toc-test/</div>
    </div>
  )
};

declare %t:case function t:render-1-simple()
{
  <root display="All Documentation"
  open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node display="node 1" open="true"></node>
    <node display="node 2" open="true"></node>
    <node display="node 3" open="true"></node>
  </root>
  ! at:equal(
    toc:render('toc-test', '/3.14', .)
    (: Handle xml:base attribute :)
    ! element { node-name(.) } {
      @* except @xml:base,
      node() }
    ,
    <div id="all_tocs" xmlns="http://www.w3.org/1999/xhtml">
      <div id="toc" class="toc">
        <div id="toc_content">
          <div id="tocs-all" class="toc_section">
            <div class="scrollable_section">
              <input id="config-filter" name="config-filter" class="config-filter"/>
              <img src="/apidoc/images/removeFilter.png" id="config-filter-close-button" class="config-filter-close-button"/>
              <div id="apidoc_tree_container" class="pjax_enabled">
                <ul id="apidoc_tree" class="treeview">
                  <li id="AllDocumentation" class="collapsible lastCollapsible">
                    <div class="hitarea collapsible-hitarea lastCollapsible-hitarea">
                    </div>
                    <a href="/3.14/" class="toc_root">All Documentation</a>
                    <ul>
                      <li class="collapsible"><span>node 1</span></li>
                      <li class="collapsible"><span>node 2</span></li>
                      <li class="collapsible lastCollapsible"><span>node 3</span></li>
                    </ul>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
        <div id="splitter"></div>
      </div>
      <div id="tocPartsDir" style="display:none;">toc-test/</div>
    </div>
  )
};

declare %t:case function t:render-1-simple-href()
{
  <root display="All Documentation"
  open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node display="node 1" href="/node/1"></node>
    <node display="node 2" open="true"></node>
    <node display="node 3" open="true"></node>
  </root>
  ! at:equal(
    toc:render('toc-test', '/3.14', .)
    //xh:a/@href/string(),
    ('/3.14/', '/3.14/node/1'))
};

declare %t:case function t:render-1-simple-uri()
{
  <root display="All Documentation"
  open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node display="node 1" open="true"></node>
    <node display="node 2" open="true"></node>
    <node display="node 3" open="true"></node>
  </root>
  ! at:equal(
    toc:render('toc-test', '/3.14', .)
    ! base-uri(.),
    'toc-test')
};

declare %t:case function t:render-async-2-content()
{
  <root display="All Documentation"
    open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node display="node 1" href="/node/1"></node>
    <node display="node 2" id="node-2" async="true">
      <node display="node 2.1"></node>
      <node display="node 2.2"></node>
    </node>
  </root>
  ! at:equal(
    toc:render('toc-test', '/3.14', .)
    (: Handle xml:base attribute :)
    ! element { node-name(.) } {
      @* except @xml:base,
      node() }
    /self::xh:ul
    ,
    <ul style="display: block;" xmlns="http://www.w3.org/1999/xhtml">
      <li class=""><span>node 2.1</span></li>
      <li class="last"><span>node 2.2</span></li>
    </ul>
  )
};

declare %t:case function t:render-async-2-placeholder()
{
  <root display="All Documentation"
    open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node display="node 1" href="/node/1"></node>
    <node display="node 2" id="node-2" async="true">
      <node display="node 2.1"></node>
      <node display="node 2.2"></node>
    </node>
  </root>
  ! at:equal(
    toc:render('toc-test', '/3.14', .)[
      base-uri(.) eq 'toc-test']
    //xh:li[@id eq 'node-2']
    ,
    <li class="expandable lastExpandable hasChildren async" id="node-2"
      xmlns="http://www.w3.org/1999/xhtml">
      <div class="hitarea expandable-hitarea lastExpandable-hitarea"></div>
      <span>node 2</span>
      <ul style="display: none;">
        <li><span class="placeholder">&#160;</span></li>
      </ul>
    </li>
  )
};

declare %t:case function t:render-2-async-uris()
{
  <root display="All Documentation"
    open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node display="node 1" href="/node/1"></node>
    <node display="node 2" id="node-2" async="true">
      <node display="node 2.1"></node>
      <node display="node 2.2"></node>
    </node>
  </root>
  ! at:equal(
    toc:render('toc-test', '/3.14', .)
    ! base-uri(.),
    ('toc-test/node-2.html', 'toc-test'))
};

declare %t:case function t:render-2-async-xdmp()
{
  <root display="All Documentation"
    open="true" xmlns="http://marklogic.com/rundmc/api/toc">
    <node display="node 1" href="/node/1">
      <node href="/js/xdmp" display="xdmp." function-count="337"
  namespace="http://marklogic.com/xdmp"
  category-bucket="MarkLogic Built-In Functions"
  function-list-page="true" async="true" id="xdmp_n9b9475fceb6b577b"
  is-javascript="true" footnote="true"
  xmlns="http://marklogic.com/rundmc/api/toc">
        <node display="node 2.1"></node>
        <node display="node 2.2"></node>
      </node>
    </node>
  </root>
  ! at:equal(
    toc:render('toc-test', '/3.14', .)
    //xh:div[@id = 'apidoc_tree_container']
,

    <div xmlns="http://www.w3.org/1999/xhtml"
    id="apidoc_tree_container" class="pjax_enabled"><ul id="apidoc_tree"
    class="treeview">
      <li id="AllDocumentation" class="collapsible lastCollapsible">
        <div class="hitarea collapsible-hitarea lastCollapsible-hitarea"></div>
        <a href="/3.14/" class="toc_root">All Documentation</a>
        <ul>
          <li class="expandable lastExpandable">
            <div class="hitarea expandable-hitarea lastExpandable-hitarea"></div>
            <a href="/3.14/node/1">node 1</a><ul style="display: none;">
            <li class="expandable lastExpandable hasChildren async" id="js_xdmp_n9b9475fceb6b577b">
              <div class="hitarea expandable-hitarea lastExpandable-hitarea"></div>
              <a href="/3.14/js/xdmp" title="http://marklogic.com/xdmp">xdmp.<span class="function_count"> (337)</span></a>
              <ul style="display: none;">
                <li><span class="placeholder">&#160;</span>
                </li>
              </ul>
            </li>
          </ul>
          </li>
        </ul>
      </li>
    </ul>
    </div>)
};

(: test/apidoc-toc.xqm :)