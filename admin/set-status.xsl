<!-- An incremental transformation, setting the "status" attribute
     of the document element, whether it already exists or not. -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:param name="status" as="xs:string"/>

  <!-- Add "status" to the document element -->
  <xsl:template mode="add-attribute" match="/*">
    <xsl:attribute name="status">
      <xsl:value-of select="$status"/>
    </xsl:attribute>
  </xsl:template>

  <!-- Boilerplate: identity transform -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates mode="add-attribute" select="."/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- By default, don't add any attributes -->
  <xsl:template mode="add-attribute" match="*"/>

</xsl:stylesheet>
