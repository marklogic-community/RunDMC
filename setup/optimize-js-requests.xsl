<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns                  ="http://www.w3.org/1999/xhtml"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs">

  <xsl:output indent="no"/>

  <!-- By default, copy everything unchanged -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- But replace the first external script reference with a reference to all-*.js -->
  <xsl:template match="script[@src][1]" priority="1">
    <xsl:variable name="filename" select="concat('/js/optimized/all-', current-dateTime(), '.js')"/>
    
    <script src="{$filename}" type="text/javascript"/>

    <!-- Also, create the new all-*.js file -->
    <xsl:result-document href="..{$filename}" method="text">
      <xsl:value-of select="../script/@src/unparsed-text(concat('..', .))" separator="&#xA;"/>
    </xsl:result-document>
  </xsl:template>

  <!-- And strip out all the other external script references -->
  <xsl:template match="script[@src]"/>

</xsl:stylesheet>

