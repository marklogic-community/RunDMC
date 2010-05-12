<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:form="http://developer.marklogic.com/site/internal/form">

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@form:label]">
    <xsl:copy>
      <!-- Add a unique id annotation to each element -->
      <xsl:attribute name="form:name">
        <!-- Include the local name of the element itself (as a human-readable id), which might be enough to uniquely identify it -->
        <xsl:value-of select="translate(local-name(.), '-', '_')"/>

        <xsl:variable name="me-and-my-like-named-repeating-elements" select=". | ( if (../@form:group-label) then ../../*[node-name(.) eq node-name(current()/..)]
                                                                                                                       /*[node-name(.) eq node-name(current())]
                                                                                                             else ../*[node-name(.) eq node-name(current())]
                                                                                 )"/>
        <xsl:variable name="other-elements-with-same-local-name" select="(//* except $me-and-my-like-named-repeating-elements)
                                                                         [local-name(.) eq local-name(current())]"/>
        <!-- If the local name is not enough to uniquely identify it, then append a generated ID -->
        <xsl:if test="$other-elements-with-same-local-name">
          <xsl:text>_</xsl:text>
          <xsl:value-of select="generate-id($me-and-my-like-named-repeating-elements[1])"/>
        </xsl:if>
      </xsl:attribute>
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
