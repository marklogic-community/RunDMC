<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs">

  <xsl:template match="/">
    <!-- We're reading from a doc in one database and writing to a doc in a different database, using the same URI -->
    <xsl:result-document href="{base-uri(.)}">
      <xsl:apply-templates/>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Don't need this attribute at this stage; only used to resolve URIs of images being copied over -->
  <xsl:template match="/guide/@original-dir"/>

</xsl:stylesheet>

