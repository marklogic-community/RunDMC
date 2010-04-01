<!-- This stylesheet is for making blog comments safe -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xpath-default-namespace="http://www.w3.org/1999/xhtml">

  <!-- Copy attributes and text nodes -->
  <xsl:template match="@* | text()">
    <xsl:copy/>
  </xsl:template>

  <!-- By default, strip out element start & end tags -->
  <xsl:template match="*">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- But allow these -->
  <!-- TODO: allow <a> but with restrictions -->
  <xsl:template match="p | em | strong | b | i | br | cite | blockquote">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>


</xsl:stylesheet>
