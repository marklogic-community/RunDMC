<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs api ml">

  <xsl:import href="../../view/uri-translation.xsl"/>

  <!-- Both of these functions override functions in /view/uri-translation.xsl -->

  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="ml:external-uri-api($node)"/>
  </xsl:function>

  <!-- ASSUMPTION: This is only called on version-less paths (as they appear in the XML TOCs). -->
  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:variable name="version-path" select="concat('/apidoc/', $api:version)"/>
    <xsl:value-of>
      <xsl:value-of select="$version-path"/>
      <xsl:value-of select="if ($doc-path eq '/') then '/index.xml' else concat(ml:escape-uri($doc-path),'.xml')"/>
    </xsl:value-of>
  </xsl:function>

</xsl:stylesheet>
