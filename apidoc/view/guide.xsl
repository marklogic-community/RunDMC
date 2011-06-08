<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:map="http://marklogic.com/xdmp/map"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:x="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs api xdmp map x">

  <xsl:output indent="no"/>

  <xsl:template mode="page-specific-title" match="/guide">
    <xsl:value-of select="title"/>
  </xsl:template>

  <xsl:template mode="page-content" match="/guide">
    <!-- eventually switch to using just this
    <xsl:apply-templates mode="guide"/>
    -->
    <!-- Everything below is temporary, for development purposes. Later, assume that the guide is already converted (in the setup phase). -->
    <xsl:variable name="params">
      <!-- Ensure result of converted guide has the same URI -->
      <map:map>
        <map:entry>
          <map:key>output-uri</map:key>
          <map:value>
            <xsl:value-of select="base-uri(.)"/>
          </map:value>
        </map:entry>
      </map:map>
    </xsl:variable>
    <!-- Convert and render the guide by directly calling the setup/conversion code -->
    <xsl:copy-of select="xdmp:xslt-invoke('../setup/convert-guide.xsl', /, map:map($params/map:map))
                         /guide/(node() except title)"/>
    <!--
    <xsl:apply-templates mode="guide" select="xdmp:xslt-invoke('../setup/convert-guide.xsl', /,
                                                               map:map($params/map:map))
                                             /guide/(node() except title)"/>
                                             -->
  </xsl:template>

  <!-- Resolve the relative image URI according to the current guide -->
  <xsl:template mode="guide-att-value" match="x:img/@src">
    <xsl:value-of select="concat(api:guide-image-dir(base-uri(.)), @src)"/>
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

