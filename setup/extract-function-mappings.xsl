<!-- This stylesheet is a one-off script for generating the
     temporary config files for mapping function names
     (in search results) to the old URL in the API reference
     before api.marklogic.com is completed. -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs">

  <xsl:output indent="yes"/>

  <xsl:template match="/">
    <function-urls>
      <xsl:apply-templates select="//table[@class eq 'table-line']/tr[@class eq 'mainbody']/td[1]"/>
    </function-urls>
  </xsl:template>

  <xsl:template match="td">
    <function name="{normalize-space(.//a/b)}" url="{.//a/@href}"/>
  </xsl:template>

</xsl:stylesheet>

