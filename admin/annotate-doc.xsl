<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp form xhtml">

  <xsl:param name="template-doc"/>

<!--
<xsl:template match="/">
<xsl:copy-of select="$template-doc"/>
<xsl:apply-templates select="$template-doc/*"/>
</xsl:template>
-->

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ml:*">
    <xsl:variable name="config-node" select="$template-doc//*[deep-equal(form:path-to-me(.),
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
            <xsl:variable name="doc">
              <doc xmlns="">
                <xsl:copy-of select="node()"/>
              </doc>
            </xsl:variable>
            <xsl:copy-of select="xdmp:xslt-invoke('strip-namespaces.xsl', $doc)"/>
          </xsl:variable>
          <xsl:value-of select="$content-stripped/*/node()/xdmp:quote(.)" separator=""/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

          <!--
          <xsl:template mode="strip-namespaces" match="@* | node()">
            <xsl:copy>
              <xsl:apply-templates mode="#current" select="@* | node()"/>
            </xsl:copy>
          </xsl:template>

          <xsl:template mode="strip-namespaces" match="xhtml:*">
            <xsl:element name="{local-name()}" namespace="">
              <xsl:apply-templates mode="#current" select="@*"/>
              <xsl:apply-templates mode="#current"/>
            </xsl:element>
          </xsl:template>
          -->


  <xsl:function name="form:path-to-me" as="xs:QName+">
    <xsl:param name="element"/>
    <xsl:sequence select="for $e in $element/ancestor-or-self::* return $e/node-name(.)"/>
  </xsl:function>

</xsl:stylesheet>
