<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
  xmlns:api="http://marklogic.com/rundmc/api"
  exclude-result-prefixes="xs apidoc">

  <xsl:template match="/">
                                                              <!-- Function names aren't unique thanks to the way *:polygon()
                                                                   is documented. -->
    <xsl:apply-templates select="apidoc:module/apidoc:function[not(@fullname = preceding-sibling::apidoc:function/@fullname)]"/>
  </xsl:template>

  <!-- Extract each function as its own document -->
  <xsl:template match="apidoc:function">
    <xsl:result-document href="/apidoc/{@lib}:{@name}.xml">
      <!-- This wrapper is necessary because the *:polygon() functions
           are each (dubiously) documented as two separate functions so
           that raises the possibility of needing to include two different
           <api:function> elements in the same page. -->
      <api:function-page>
        <xsl:apply-templates mode="copy" select="../apidoc:function[@fullname eq current()/@fullname]"/>
      </api:function-page>
    </xsl:result-document>
  </xsl:template>

  <!-- By default, copy everything unchanged -->
  <xsl:template mode="copy" match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Copy elements, but rename "apidoc" to "api" so we never have any namespace clashes -->
  <xsl:template mode="copy" match="apidoc:*">
    <xsl:element name="{name()}" namespace="http://marklogic.com/rundmc/api">
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
