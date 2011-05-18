<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs raw">

  <xdmp:import-module href="/apidoc/setup/raw-docs-access.xqy" namespace="http://marklogic.com/rundmc/raw-docs-access"/>

  <xsl:template match="/">
    <!-- We're reading from a doc in one database and writing to a doc in a different database, using a similar URI -->
    <xsl:result-document href="{raw:target-guide-uri(.)}">
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

