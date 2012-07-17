<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs">

  <!-- Set @status to "Published" or "Draft" -->
  <xsl:import href="set-doc-attribute.xsl"/>

  <!-- If we're publishing the doc, then put it at the top of the list (latest chronologically) -->
  <xsl:template match="ml:created[$att-name  eq 'status']
                                 [$att-value eq 'Published']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="current-dateTime()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

