<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xmlns:label            ="http://developer.marklogic.com/site/internal/form/attribute-labels"
  xmlns:values           ="http://developer.marklogic.com/site/internal/form/values"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs xdmp label values">

  <!-- temporary -->
  <xsl:output indent="yes"/>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*[not(form:is-attribute-field(.))],
                                                   @*[    form:is-attribute-field(.) ],
                                                   node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@label:* | @values:*"/>

  <xsl:template match="@*[form:is-attribute-field(.)]">
    <xsl:element name="{name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates mode="element-annotation" select="../(@label:* | @values:*)[local-name(.) eq local-name(current())]"/>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

          <xsl:template mode="element-annotation" match="@label:*">
            <xsl:attribute name="form:label">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:template>

          <xsl:template mode="element-annotation" match="@values:*">
            <xsl:attribute name="form:values">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:template>

  <xsl:function name="form:is-attribute-field" as="xs:boolean">
    <xsl:param name="att" as="attribute()"/> 
    <xsl:sequence select="not(form:has-reserved-name($att)) and (local-name($att) =
                                                                $att/../@label:*/local-name(.))"/>
  </xsl:function>

          <xsl:function name="form:has-reserved-name" as="xs:boolean">
            <xsl:param name="att" as="attribute()"/>
            <xsl:variable name="filtered-by-name" select="$att except $att/../(@form:* | @label:* | @values:*)"/>
            <xsl:sequence select="empty($filtered-by-name)"/>
          </xsl:function>

</xsl:stylesheet>
