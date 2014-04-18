<!-- This stylesheet renders the pre-generated XML TOC
     into HTML to be cached by browsers.
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
                xmlns:toc="http://marklogic.com/rundmc/api/toc"
                xmlns:u  ="http://marklogic.com/rundmc/util"
                xmlns:ml="http://developer.marklogic.com/site/internal"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns="http://www.w3.org/1999/xhtml"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs api apidoc toc u ml xdmp">

  <!-- TODO this does not seem to import anything? -->
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/toc"
      href="toc.xqm"/>

  <xsl:param name="toc-url"/>

  <!-- Optional version-specific prefix for link hrefs, e.g., "/4.2" -->
  <xsl:param name="prefix-for-hrefs"/>

  <xsl:variable name="toc-parts-dir"
                select="concat($toc-url,'/')"/>

  <xsl:template match="/">
    <xsl:message>Creating TOC <xsl:value-of select="$toc-url"/></xsl:message>
    <xsl:result-document href="{$toc-url}">
      <!--
           Write placeholder elements for use by toc_filter.js toc_init.
      -->
      <div id="all_tocs">
        <div id="tocPartsDir" style="display:none;">
          <xsl:value-of select="$toc-parts-dir"/>
        </div>

        <div id="toc" class="toc">
          <div id="toc_content">
            <xsl:apply-templates mode="toc-content" select="/all-tocs"/>
          </div>

          <div id="splitter"/>

        </div>
      </div>
    </xsl:result-document>
  </xsl:template>

  <xsl:template mode="toc-label"
                match="toc:functions|toc:categories"
                >XQuery/XSLT</xsl:template>
  <xsl:template mode="toc-label"
                match="toc:guides">Guides</xsl:template>
  <xsl:template mode="toc-label"
                match="toc:rest-resources"
                >REST API</xsl:template>
  <xsl:template mode="toc-label"
                match="toc:java"
                >Java API</xsl:template>
  <xsl:template mode="toc-label"
                match="toc:other"
                >Other Docs</xsl:template>

  <xsl:template mode="toc-content" match="/all-tocs">
    <div id="tocs-all" class="toc_section">
      <div class="scrollable_section">
        <input id="config-filter" name="config-filter"
               class="config-filter" />
        <img src="/apidoc/images/removeFilter.png"
             id="config-filter-close-button"
             class="config-filter-close-button"/>
        <div id="apidoc_tree_container"
             class="pjax_enabled">
          <ul id="apidoc_tree" class="treeview">
            <li id="AllDocumentation"
                class="collapsible lastCollapsible">
              <div class="hitarea collapsible-hitarea
                          lastCollapsible-hitarea"></div>
              <a href="/" class="toc_root">All documentation</a>
              <ul>
                <xsl:for-each select="*">
                  <xsl:apply-templates select="node"/>
                </xsl:for-each>
              </ul>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </xsl:template>

  <xsl:template mode="id-att" match="node"/>

  <!-- Include an ID on nodes that have one already -->
  <xsl:template mode="id-att" match="node[@id]">
    <xsl:attribute name="id">
      <xsl:value-of select="toc:node-id(.)"/>
    </xsl:attribute>
  </xsl:template>

  <!--
      This is a TOC leaf node.
      If async, its @id will point the way.
  -->
  <xsl:template match="node">
    <xsl:variable name="class">
      <xsl:apply-templates mode="class" select="."/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="class-last" select="."/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="class-hasChildren" select="."/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="class-initialized" select="."/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="class-async" select="."/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="class-wrap-titles" select="."/>
    </xsl:variable>
    <li class="{$class}">
      <xsl:apply-templates mode="id-att"   select="."/>
      <xsl:apply-templates mode="hit-area" select="."/>
      <xsl:apply-templates mode="link"     select="."/>
      <xsl:apply-templates mode="children" select="."/>
    </li>
  </xsl:template>

  <xsl:template mode="class" priority="1"
               match="node[@open]">collapsible</xsl:template>
  <xsl:template mode="class"
                match="node[node] ">expandable</xsl:template>
  <xsl:template mode="class"
                match="node"/>

  <xsl:template mode="class-last" priority="2"
                match="node[empty((parent::toc:*|.)/following-sibling::*)][@open]">
    lastCollapsible
  </xsl:template>
  <xsl:template mode="class-last" priority="1"
                match="node[empty((parent::toc:*|.)/following-sibling::*)][node]">
    lastExpandable
  </xsl:template>
  <xsl:template mode="class-last"
                match="node[empty((parent::toc:*|.)/following-sibling::*)]">
    last
  </xsl:template>
  <!-- default -->
  <xsl:template mode="class-last" match="node"/>

  <!-- Include on nodes that will be loaded asynchronously -->
  <xsl:template mode="class-hasChildren"
                match="node[@async]">hasChildren</xsl:template>
  <xsl:template mode="class-hasChildren"
                match="node"/>

  <!-- Include on nodes that have an @id
       (used by list pages to identify the relevant TOC section)
       but that aren't loaded asynchronously
       (because they're already loaded)
  -->
  <xsl:template mode="class-initialized"
                match="node[@id][not(@async)]">loaded initialized</xsl:template>
  <xsl:template mode="class-initialized"
                match="node"/>

  <!--
      Mark the asynchronous (unpopulated) nodes as such,
      for the treeview JavaScript.
  -->
  <xsl:template mode="class-async" match="node[@async]">async</xsl:template>
  <xsl:template mode="class-async" match="node"/>

  <!-- Mark the nodes whose descendant titles should be wrapped -->
  <xsl:template mode="class-wrap-titles"
                match="node[@wrap-titles]">wrapTitles</xsl:template>
  <xsl:template mode="class-wrap-titles"
                match="node"/>

  <xsl:template mode="hit-area" match="node"/>
  <xsl:template mode="hit-area" match="node[node]">
    <xsl:variable name="class">
      <xsl:apply-templates mode="hit-area-class"
                           select="."/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="hit-area-class-last"
                           select="."/>
    </xsl:variable>
    <div class="{$class}"/>
  </xsl:template>

  <xsl:template mode="hit-area-class"
                match="node[@open]">hitarea collapsible-hitarea</xsl:template>
  <xsl:template mode="hit-area-class"
                match="node       ">hitarea expandable-hitarea</xsl:template>

  <xsl:template mode="hit-area-class-last" priority="1"
                match="node[empty((parent::toc:*|.)/following-sibling::*)][@open]">
    lastCollapsible-hitarea
  </xsl:template>
  <xsl:template mode="hit-area-class-last"
                match="node[empty((parent::toc:*|.)/following-sibling::*)]">
    lastExpandable-hitarea
  </xsl:template>
  <xsl:template mode="hit-area-class-last"
                match="node               "/>

  <xsl:template mode="link" match="node">
    <span>
      <xsl:apply-templates mode="node-display" select="."/>
    </span>
  </xsl:template>

  <xsl:template mode="link" match="node[@href]">
    <xsl:variable name="href">
      <xsl:value-of select="$prefix-for-hrefs"/>
      <xsl:apply-templates mode="link-href" select="."/>
    </xsl:variable>
    <a href="{$href}">
      <xsl:apply-templates mode="external-atts" select="."/>
      <xsl:apply-templates mode="title-att" select="."/>
      <xsl:apply-templates mode="node-display" select="."/>
    </a>
  </xsl:template>

  <!-- For external links (outside the docs template) -->
  <xsl:template mode="external-atts" match="node"/>
  <xsl:template mode="external-atts" match="node[@external]">
    <xsl:attribute name="class" select="'external'"/>
    <xsl:attribute name="target" select="'_blank'"/>
  </xsl:template>


  <xsl:template mode="node-display" match="node">
    <xsl:value-of select="@display"/>
  </xsl:template>

  <xsl:template mode="node-display" match="node[@function-count]">
    <xsl:next-match/>
    <span class="function_count">
      <xsl:text> (</xsl:text>
      <xsl:value-of select="@function-count"/>
      <xsl:text>)</xsl:text>
    </span>
  </xsl:template>


  <!-- For most cases,
       just append the @href value after the optional version prefix
  -->
  <xsl:template mode="link-href" match="node">
    <xsl:value-of select="@href"/>
  </xsl:template>

  <!-- But when the @href value is just "/",
       leave it out when the version is specified explicitly
       (e.g., /4.2 instead of /4.2/)
  -->
  <xsl:template mode="link-href"
                match="node[string($prefix-for-hrefs)][@href eq '/']"/>


  <xsl:template mode="title-att" match="node"/>
  <xsl:template mode="title-att" match="node[@namespace]">
    <xsl:attribute name="title" select="@namespace"/>
  </xsl:template>

  <!-- Don't ever display "all" at the top (in the blue buttons) -->
  <xsl:template mode="all-suffix"
                match="*[@top-control]"/>
  <xsl:template mode="all-suffix" match="*"> all</xsl:template>

  <!-- top_control is styled to appear at the top as a blue button -->
  <xsl:template mode="top_control-class"
                match="*"/>
  <xsl:template mode="top_control-class"
                match="*[@top-control]">top_control</xsl:template>

  <!-- this distinction is necessary for top_control (blue) buttons
       in order to get the correct positioning offsets
  -->
  <xsl:template mode="local_control-class"
                match="node">local_control</xsl:template>

  <!-- This can also be next-match for node[@async] ??? -->
  <xsl:template mode="children" match="node"/>

  <!-- This should also be next-match for node[@async] -->
  <xsl:template mode="children" match="node[node]">
    <xsl:variable name="display-type">
      <xsl:apply-templates mode="ul-display-type"
                           select="."/>
    </xsl:variable>
    <ul style="display: {$display-type};">
      <xsl:apply-templates select="node"/>
    </ul>
  </xsl:template>

  <!--
      Nodes to be loaded asynchronously
      TODO the document URI needs to handle xquery vs javascript
  -->
  <xsl:template mode="children"
                match="node[@async]"
                priority="1">
    <!-- The empty placeholder -->
    <ul style="display: none">
      <li><span class="placeholder">&#160;</span></li>
    </ul>
    <xsl:if test="not(@duplicate)">
      <xsl:variable name="uri"
                    select="toc:uri(
                            $toc-parts-dir,
                            @id,
                            if (ancestor::toc:functions-javascript) then 'javascript'
                            else ())"/>
      <!-- New document with the contents of the TOC node. -->
      <xsl:message>render-toc mode=children node[@async] <xsl:value-of
      select="$uri"/> <xsl:value-of select="xdmp:describe(.)"/>
      </xsl:message>
      <xsl:result-document href="{$uri}">
        <xsl:next-match/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="ul-display-type"
                match="node[@open or @async]">block</xsl:template>
  <xsl:template mode="ul-display-type"
                match="node">none</xsl:template>

</xsl:stylesheet>
