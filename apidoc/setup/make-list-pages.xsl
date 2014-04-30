<!--
    This stylesheet constructs the XML-based TOC, including
    introductory HTML for each section. This is used to generate
    both the HTML TOC and the "list" pages with their introductory
    content.
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:toc="http://marklogic.com/rundmc/api/toc"
                xmlns:ml="http://developer.marklogic.com/site/internal"
                xmlns:u="http://marklogic.com/rundmc/util"
                xmlns:xdmp="http://marklogic.com/xdmp"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs api ml u toc">

  <xdmp:import-module
      namespace="http://developer.marklogic.com/site/internal"
      href="/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api"
      href="/apidoc/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/util"
      href="/lib/util-2.xqy"/>

  <xsl:variable name="root" select="/"/>

  <xsl:variable name="title-aliases" select="u:get-doc('/apidoc/config/title-aliases.xml')/aliases"/>

  <xsl:template match="/">
    <!-- Set up the docs page for this version -->
    <xsl:result-document href="{api:internal-uri('/')}">
      <xsl:comment>This page was auto-generated. The resulting content is driven     </xsl:comment>
      <xsl:comment>by a combination of this page and /apidoc/config/document-list.xml</xsl:comment>
      <api:docs-page disable-comments="yes">
        <xsl:for-each
            select="/toc:root/toc:node[@id eq 'guides']/toc:node[@guide]">
          <api:user-guide href="{@href}" display="{@display}">
            <!-- Put applicable title aliases here to help facilitate automatic link creation at render time -->
            <xsl:copy-of select="$title-aliases/guide/alias
                                 [../alias/normalize-space(lower-case(.)) =
                                 current()/@display/normalize-space(lower-case(.))]"/>
          </api:user-guide>
        </xsl:for-each>
        <xsl:comment>copied from /apidoc/config/title-aliases.xml:</xsl:comment>
        <xsl:copy-of select="$title-aliases/auto-link"/>
      </api:docs-page>
    </xsl:result-document>
    <!-- Find each function list and help page URL -->
    <xsl:for-each select="distinct-values(//toc:node[@function-list-page or @admin-help-page]/@href)">
      <xsl:result-document href="{api:internal-uri(.)}">
        <!-- Process the first one of each that has a title (and consequently intro or help content) -->
        <xsl:apply-templates select="($root//toc:node[@href eq current()])[toc:title][1]"/>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="toc:node[@admin-help-page]">
    <xsl:variable name="container-toc-section-id">
      <xsl:apply-templates mode="container-toc-section-id" select="."/>
    </xsl:variable>
    <api:help-page disable-comments="yes" container-toc-section-id="{$container-toc-section-id}">
      <xsl:apply-templates select="toc:title | toc:content"/>
    </api:help-page>
  </xsl:template>

  <xsl:template match="toc:content">
    <api:content>
      <xsl:apply-templates mode="to-xhtml"/>
    </api:content>
  </xsl:template>

  <!-- Help index page is at the top -->
  <xsl:template match="toc:content[@auto-help-list]">
    <api:content>
      <xsl:variable name="content-without-namespace">
        <p>The following is an alphabetical list of the Admin Interface's help pages:</p>
        <ul>
          <xsl:variable name="help-nodes" select="..//toc:node"/>
          <!-- only select the first node for each unique @href -->
          <xsl:apply-templates mode="help-page-item" select="for $this in $help-nodes return $this[. is $help-nodes[@href eq $this/@href][1]]">
            <!-- Sort alphabetically by title -->
            <xsl:sort select="toc:title"/>
          </xsl:apply-templates>
          <!-- hierarchical list doesn't add any value since we already have it in the TOC
               <xsl:apply-templates mode="help-page-list" select="toc:node"/>
          -->
        </ul>
      </xsl:variable>
      <xsl:apply-templates mode="to-xhtml" select="$content-without-namespace"/>
    </api:content>
  </xsl:template>

  <xsl:template mode="help-page-item" match="toc:node">
    <li>
      <a href="{@href}">
        <xsl:value-of select="toc:title"/>
      </a>
    </li>
  </xsl:template>


  <xsl:template match="toc:node[@function-list-page]">
    <xsl:variable name="container-toc-section-id">
      <xsl:apply-templates mode="container-toc-section-id" select="."/>
    </xsl:variable>
    <api:list-page disable-comments="yes"
                   container-toc-section-id="{$container-toc-section-id}">
      <xsl:copy-of select="@category-bucket"/>
      <!-- copy @is-javascript if present -->
      <xsl:copy-of select="@is-javascript"/>

      <!-- can be used to trigger different display options -->
      <xsl:copy-of select="@type"/>

      <!-- TODO: add these to the input when applicable (toc-generation code) -->
      <xsl:copy-of select="@prefix | @namespace"/>

      <xsl:apply-templates select="toc:title | toc:intro"/>

      <!-- Make an entry for the document pointed to by each descendant leaf node -->
      <xsl:for-each select=".//toc:node[not(toc:node)]">
        <!-- don't list multiple *:polygon() functions; just the first -->
        <xsl:apply-templates mode="list-entry"
                             select="doc(api:internal-uri(@href))
                                     /api:function-page/api:function[1]">
          <xsl:with-param name="toc-node" select="."/>
        </xsl:apply-templates>
      </xsl:for-each>

    </api:list-page>
  </xsl:template>

  <!-- The container ID comes from the nearest ancestor (or self) that is marked as asynchronously loaded,
       unless nothing above this level is marked as such, in which case we use the nearest ID. -->
  <xsl:template mode="container-toc-section-id" match="toc:node">
    <xsl:value-of select="(ancestor-or-self::toc:node[@async][1],
                          ancestor-or-self::toc:node[@id]   [1])[1]/@id"/>
  </xsl:template>


  <xsl:template mode="list-entry" match="api:function">
    <xsl:param name="toc-node"/>
    <api:list-entry href="{$toc-node/@href}">
      <api:name>
        <!-- Special-case the cts accessor functions; they should be indented -->
        <xsl:if test="@lib eq 'cts' and contains($toc-node/@display, '-query-')">
          <xsl:attribute name="indent" select="'yes'"/>
        </xsl:if>
        <!-- Function name; prefer @list-page-display, if present -->
        <xsl:value-of select="($toc-node/@list-page-display,
                              $toc-node/@display)[1]"/>
      </api:name>
      <api:description>
        <!-- Use the same code that docapp uses for extracting the summary (first line) -->
        <xsl:value-of select="concat(tokenize(api:summary,'\.(\s+|\s*$)')[1], '.')"/>
      </api:description>
    </api:list-entry>
  </xsl:template>

  <xsl:template match="toc:title">
    <api:title>
      <xsl:apply-templates mode="to-xhtml"/>
    </api:title>
  </xsl:template>

  <xsl:template match="toc:intro">
    <api:intro>
      <xsl:apply-templates mode="to-xhtml"/>
    </api:intro>
  </xsl:template>

  <xsl:template mode="to-xhtml" match="@* | text()">
    <xsl:copy/>
  </xsl:template>

  <xsl:template mode="to-xhtml" match="*">
    <xsl:element name="{local-name(.)}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
