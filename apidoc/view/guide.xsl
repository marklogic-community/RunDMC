<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:map="http://marklogic.com/xdmp/map"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:x="http://www.w3.org/1999/xhtml"
  xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs api xdmp map x raw">

  <xdmp:import-module href="/apidoc/setup/raw-docs-access.xqy" namespace="http://marklogic.com/rundmc/raw-docs-access"/>

  <xsl:output indent="no"/>

  <!-- Only set to true in development, not in production. -->
  <xsl:variable name="convert-at-render-time" select="true()"/>

  <xsl:template mode="page-specific-title" match="/guide">
    <xsl:value-of select="title"/>
  </xsl:template>

  <xsl:template mode="page-content" match="/guide">
    <xsl:choose>
      <!-- The normal case: the guide is already converted (at "build time", i.e. the setup phase). -->
      <xsl:when test="not($convert-at-render-time)">
        <xsl:apply-templates mode="guide"/>
      </xsl:when>
      <!-- For development purposes only. Normally, assume that the guide is already converted (in the setup phase). -->
      <xsl:otherwise>
        <p>WARNING: This was converted directly from the raw docs database for convenience in development.
           Set the $convert-at-render-time flag to false in production (and this warning will go away).</p>
        <!-- Convert and render the guide by directly calling the setup/conversion code -->
        <xsl:apply-templates mode="guide"  select="xdmp:xslt-invoke('../setup/convert-guide.xsl',
                                                                    $raw:guide-docs[raw:target-guide-uri(.) eq base-uri(current())])
                                                   /guide/node()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Don't copy the <title> element -->
  <xsl:template mode="guide" match="guide/title"/>

  <!-- Resolve the relative image URI according to the current guide -->
  <xsl:template mode="guide-att-value" match="x:img/@src">
    <xsl:value-of select="concat(api:guide-image-dir(base-uri(.)), .)"/>
  </xsl:template>


  <!-- Boilerplate copying code -->
  <xsl:template mode="guide" match="node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="guide" match="@*">
    <xsl:attribute name="{name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates mode="guide-att-value" select="."/>
    </xsl:attribute>
  </xsl:template>

          <xsl:template mode="guide-att-value" match="@*">
            <xsl:value-of select="."/>
          </xsl:template>

</xsl:stylesheet>

