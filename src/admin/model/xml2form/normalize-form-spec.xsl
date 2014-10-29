<!-- This stylesheet is applied as a pre-process to the XML source for a form,
     before the rules in form.xsl are applied.

     It converts attribute fields to element fields in order to simplify the
     form generation (so we don't have to worry about handling two different
     kinds of fields). We also flag each element field we create, so the code
     knows to convert it back to an element after the user is done editing.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xmlns:label            ="http://developer.marklogic.com/site/internal/form/attribute-labels"
  xmlns:values           ="http://developer.marklogic.com/site/internal/form/values"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs label values">

  <!-- By default, copy everything unchanged -->
  <xsl:template match="@* | node()">
    <xsl:copy>                                     <!-- Make sure we process all other attributes before
                                                        the ones we'll be converting to elements. -->
      <xsl:apply-templates mode="#current" select="@*[not(form:is-attribute-field(.))],
                                                   @*[    form:is-attribute-field(.) ],
                                                   node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Don't copy any of these attributes -->
  <xsl:template match="@label:* | @values:*"/>

  <!-- Convert editable attribute form fields to element fields, to facilitate easier form generation -->
  <xsl:template match="@*[form:is-attribute-field(.)]">
    <xsl:element name="{name()}" namespace="{namespace-uri()}">
      <!-- Flag it as an attribute, so it can be converted back later -->
      <xsl:attribute name="form:is-attribute" select="'yes'"/>
      <!-- Convert the attribute annotations to element annotations -->
      <xsl:apply-templates mode="element-annotation" select="../(@label:* | @values:*)[local-name(.) eq local-name(current())]"/>
      <!-- The value of the attribute becomes the value of the form field -->
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

          <!-- Convert attribute label to element label -->
          <xsl:template mode="element-annotation" match="@label:*">
            <xsl:attribute name="form:label">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:template>

          <!-- Convert attribute value enumeration to element value enumeration -->
          <xsl:template mode="element-annotation" match="@values:*">
            <xsl:attribute name="form:values">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:template>

  <!-- An attribute is an editable form field if it doesn't have a reserved name AND it has a corresponding label associated with it -->
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
