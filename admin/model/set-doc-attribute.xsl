<!-- An incremental transformation, setting an attribute value
     of the document element, whether it already exists or not. -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:param name="att-name" as="xs:string"/>  <!-- E.g., "status" -->
  <xsl:param name="att-value" as="xs:string"/> <!-- E.g., "Published" -->

  <!-- Add the attribute to the document element -->
  <xsl:template mode="add-attribute" match="/*">
    <xsl:attribute name="{$att-name}">
      <xsl:value-of select="$att-value"/>
    </xsl:attribute>
  </xsl:template>

  <!-- Boilerplate: identity transform -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!-- Added after existing attributes, so if an attribute with the
           same name already exists, this one (added after) will take precedence. -->
      <xsl:apply-templates mode="add-attribute" select="."/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- By default, don't add any attributes -->
  <xsl:template mode="add-attribute" match="*"/>

</xsl:stylesheet>
