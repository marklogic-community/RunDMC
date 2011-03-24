<!-- This stylesheet constructs the XML-based TOC, including
     introductory HTML for each section. This is used to generate
     both the HTML TOC and the "list" pages with their introductory
     content. -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs api ml">

  <xsl:import href="../view/page.xsl"/>

  <xsl:variable name="root" select="/"/>

  <xsl:template match="/">
    <!-- Find each unique container page (not a leaf/function) -->
    <xsl:for-each select="distinct-values(//node[node]/@href)">
      <xsl:result-document href="{ml:internal-uri(.)}">
        <!-- Process the first one of each; it contains the intro text we need, etc. -->
        <xsl:apply-templates select="($root//node[@href eq current()])[1]"/>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="node">
                            <!-- TODO: add @title-prefix to more cases in the input -->
    <api:list-page title-prefix="{@title-prefix}" disable-comments="yes">

      <!-- TODO: add these to the input when applicable (toc-generation code) -->
      <xsl:copy-of select="@prefix | @namespace"/>

      <xsl:apply-templates select="intro"/>

      <!-- Make an entry for the document pointed to by each descendant leaf node -->
      <xsl:for-each select=".//node[not(node)]">
        <xsl:sort select="@display"/>
        <xsl:apply-templates mode="list-entry" select="doc(ml:internal-uri(@href))
                                                       /api:function-page/api:function[1]"/> <!-- don't list multiple *:polygon() functions;
                                                                                                 just the first -->
      </xsl:for-each>

    </api:list-page>
  </xsl:template>

          <xsl:template mode="list-entry" match="api:function">
            <api:list-entry>
              <api:name>
                <!-- Special-case the cts accessor functions; they should be indented -->
                <xsl:if test="@lib eq 'cts' and contains(@fullname, '-query-')">
                  <xsl:attribute name="indent" select="'yes'"/>
                </xsl:if>
                <!-- Function name -->
                <xsl:value-of select="@fullname"/>
              </api:name>
              <api:description>
                <!-- Use the same code that docapp uses for extracting the summary (first line) -->
                <xsl:value-of select="concat(tokenize(api:summary,'\.(\s+|\s*$)')[1], '.')"/>
              </api:description>
            </api:list-entry>
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
