<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Strip off the XHTML namespace -->
  <xsl:template match="*[namespace-uri(.) eq 'http://www.w3.org/1999/xhtml']" priority="1">
    <xsl:element name="{local-name(.)}" namespace="">
      <xsl:apply-templates select="@* | node()"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
