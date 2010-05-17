<!-- This stylesheet takes an existing XML document and adds all
     the form configuration annotations to it (form field labels,
     enumerated values, form control type, etc.).
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs xdmp form xhtml"> <!-- do NOT exclude "ml", because we rely on it being 
                                                     included in the doc wrapper passed to xdmp:quote -->

  <!-- The form configuration document is passed in as a top-level parameter. -->
  <xsl:param name="form-config"/>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ml:*">
    <xsl:variable name="config-node" select="$form-config//*[deep-equal(form:path-to-me(.),
                                                                        form:path-to-me(current()))][1]"/>
    <xsl:copy>
      <!-- Add applicable annotations to each element -->
      <xsl:apply-templates select="$config-node/@*"/>
      <xsl:if test="preceding-sibling::*[1][node-name(.) eq node-name(current())]">
        <xsl:attribute name="form:subsequent-item">yes</xsl:attribute>
      </xsl:if>
      <!-- Attributes in the source doc override ones in the config doc -->
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="$config-node/@form:type eq 'textarea'">
          <!-- XSLTBUG workaround: whitespace-only text nodes are getting erroneously stripped unless I do it this way -->
          <xsl:variable name="content-stripped">
            <doc> <!-- wrapper to preserve whitespace and to preserve namespace context (so all ns declarations appear at top) -->
              <xsl:copy-of select="node()"/>
            </doc>
          </xsl:variable>
          <!-- Display everything but the outer wrapper element (which includes all the namespace declarations) -->
          <xsl:value-of select="substring-before(
                                  substring-after(xdmp:quote($content-stripped/*), '>'),
                                  '&lt;/doc>'
                                )"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="form:path-to-me" as="xs:QName+">
    <xsl:param name="element"/>
    <xsl:sequence select="for $e in $element/ancestor-or-self::* return $e/node-name(.)"/>
  </xsl:function>

</xsl:stylesheet>
