<!-- This stylesheet constructs the XML-based TOC, including
     introductory HTML for each section. This is used to generate
     both the HTML TOC and the "list" pages with their introductory
     content. -->
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

  <xsl:import href="../view/uri-translation.xsl"/>

  <xdmp:import-module namespace="http://marklogic.com/rundmc/api" href="/apidoc/model/data-access.xqy"/>
  <xdmp:import-module namespace="http://marklogic.com/rundmc/util" href="/lib/util-2.xqy"/>

  <xsl:variable name="root" select="/"/>

  <xsl:variable name="title-aliases" select="u:get-doc('/apidoc/config/title-aliases.xml')/aliases"/>

  <xsl:template match="/">
    <!-- Set up the docs page for this version -->
    <xsl:result-document href="{ml:internal-uri('/')}">
      <xsl:comment>This page was auto-generated. The resulting content is driven     </xsl:comment>
      <xsl:comment>by a combination of this page and /apidoc/config/document-list.xml</xsl:comment>
      <api:docs-page disable-comments="yes">
        <xsl:for-each select="/all-tocs/toc:guides//node[@guide]">
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
    <xsl:for-each select="distinct-values(//node[@function-list-page or @admin-help-page]/@href)">
      <xsl:result-document href="{ml:internal-uri(.)}">
        <!-- Process the first one of each; it contains the intro text we need, etc. -->
        <xsl:apply-templates select="($root//node[@href eq current()])[1]"/>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="node[@admin-help-page]">
    <xsl:variable name="container-toc-section-id">
      <xsl:apply-templates mode="container-toc-section-id" select="."/>
    </xsl:variable>
    <api:help-page disable-comments="yes" container-toc-section-id="{$container-toc-section-id}">
      <xsl:apply-templates mode="help-page-content" select="."/>
    </api:help-page>
  </xsl:template>

          <!-- Help index page is at the top -->
          <xsl:template mode="help-page-content" match="toc:help/node">
            <api:title>Admin Interface Help Pages</api:title>
            <api:content>
              <xsl:variable name="content-without-namespace">
                <p>The following is an alphabetical list of the Admin Interface's help pages:</p>
                <ul>
                  <xsl:variable name="help-nodes" select=".//node"/>
                                                                     <!-- only select the first node for each unique @href -->
                  <xsl:apply-templates mode="help-page-item" select="for $this in $help-nodes return $this[. is $help-nodes[@href eq $this/@href][1]]">
                    <!-- Sort alphabetically by title -->
                    <xsl:sort select="title"/>
                  </xsl:apply-templates>
                  <!-- hierarchical list doesn't add any value since we already have it in the TOC
                  <xsl:apply-templates mode="help-page-list" select="node"/>
                  -->
                </ul>
              </xsl:variable>
              <xsl:apply-templates mode="to-xhtml" select="$content-without-namespace"/>
            </api:content>
          </xsl:template>

                  <xsl:template mode="help-page-item" match="node">
                    <li>
                      <a href="{@href}">
                        <xsl:value-of select="title"/>
                      </a>
                    </li>
                  </xsl:template>

                  <!--
                  <xsl:template mode="help-page-list" match="node"/>
                                                             <!- - only match the first node for each unique @href - ->
                  <xsl:template mode="help-page-list" match="node[. is $help-nodes[@href eq current()/@href][1]]
                                                           | node[not(@href)]"> <!- - container nodes (e.g., geospatial) - ->
                    <li>
                      <xsl:apply-templates mode="help-page-item-content" select="."/>
                      <xsl:variable name="content">
                        <xsl:apply-templates mode="#current" select="node"/>
                      </xsl:variable>
                      <xsl:if test="$content/node()">
                        <ul>
                          <xsl:copy-of select="$content"/>
                        </ul>
                      </xsl:if>
                    </li>
                  </xsl:template>

                          <!- - help page link - ->
                          <xsl:template mode="help-page-item-content" match="node[@href]">
                            <a href="{@href}">
                              <xsl:value-of select="title"/>
                            </a>
                          </xsl:template>

                          <!- - help group container (e.g., geospatial) - ->
                          <xsl:template mode="help-page-item-content" match="node">
                            <span>
                              <xsl:value-of select="@display"/>
                            </span>
                          </xsl:template>
                          -->

          <!-- Everything else is a regular help page -->
          <xsl:template mode="help-page-content" match="node">
            <xsl:apply-templates select="title | content"/>
          </xsl:template>

                  <xsl:template match="content">
                    <api:content>
                      <xsl:apply-templates mode="to-xhtml"/>
                    </api:content>
                  </xsl:template>


  <xsl:template match="node[@function-list-page]">
    <xsl:variable name="container-toc-section-id">
      <xsl:apply-templates mode="container-toc-section-id" select="."/>
    </xsl:variable>
    <api:list-page disable-comments="yes" container-toc-section-id="{$container-toc-section-id}">
      <xsl:copy-of select="@category-bucket"/>

      <!-- can be used to trigger different display options -->
      <xsl:copy-of select="@type"/>

      <!-- TODO: add these to the input when applicable (toc-generation code) -->
      <xsl:copy-of select="@prefix | @namespace"/>

      <xsl:apply-templates select="title | intro"/>

      <!-- Make an entry for the document pointed to by each descendant leaf node -->
      <xsl:for-each select=".//node[not(node)]">
        <!-- They're already sorted, and not necessarily just alphabetically (as with GET/POST/DELETE for REST resources).
        <xsl:sort select="@display"/>
        -->
<!--
<xsl:if test="@href eq '/REST/manage/v1/forests&gt;view=schema'">
<xsl:value-of select="xdmp:log(ml:internal-uri(translate(@href,'>','@')))" xmlns:xdmp="http://marklogic.com/xdmp"/>
        <xsl:apply-templates mode="list-entry" select="doc(ml:internal-uri(translate(@href,'>','@')))
                                                       /api:function-page/api:function[1]"/>
                                                       -->
        <xsl:apply-templates mode="list-entry" select="doc(ml:internal-uri(@href))
                                                       /api:function-page/api:function[1]"> <!-- don't list multiple *:polygon() functions; just the first -->
          <xsl:with-param name="toc-node" select="."/>
        </xsl:apply-templates>
<!--
</xsl:if>
-->
      </xsl:for-each>

    </api:list-page>
  </xsl:template>

          <!-- The container ID comes from the nearest ancestor (or self) that is marked as asynchronously loaded,
               unless nothing above this level is marked as such, in which case we use the nearest ID. -->
          <xsl:template mode="container-toc-section-id" match="node">
            <xsl:value-of select="(ancestor-or-self::node[@async][1],
                                   ancestor-or-self::node[@id]   [1])[1]/@id"/>
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

  <xsl:template match="title">
    <api:title>
      <xsl:apply-templates mode="to-xhtml"/>
    </api:title>
  </xsl:template>

  <xsl:template match="intro">
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
