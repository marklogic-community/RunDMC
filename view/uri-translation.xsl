<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml">

  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()*"/>
    <xsl:sequence select="ml:external-uri-main($node)"/>
  </xsl:function>

  <!-- Mapping of internal->external URIs for main server -->
  <xsl:function name="ml:external-uri-main" as="xs:string">
    <xsl:param name="node" as="node()*"/>
    <xsl:variable name="doc-path" select="base-uri($node)"/>
    <xsl:sequence select="if ($doc-path eq '/index.xml') then '/' else substring-before($doc-path, '.xml')"/>
  </xsl:function>

  <!-- Mapping of internal->external URIs for API server -->
  <xsl:function name="ml:external-uri-api" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="ml:external-uri-for-string(base-uri($node))"/>
  </xsl:function>

          <!-- Account for "/apidoc" prefix in internal/external URI mappings -->
          <xsl:function name="ml:external-uri-for-string" as="xs:string">
            <xsl:param name="doc-uri" as="xs:string"/>
            <xsl:variable name="version" select="substring-before(substring-after($doc-uri,'/apidoc/'),'/')"/>
            <xsl:variable name="versionless-path" select="if ($version) then substring-after($doc-uri,concat('/apidoc/',$version))
                                                                        else substring-after($doc-uri,'/apidoc')"/>
            <xsl:variable name="path" select="ml:unescape-uri($versionless-path)"/>
            <xsl:value-of>
              <!-- Map "/index.xml" to "/" and "/foo.xml" to "/foo" -->
              <xsl:value-of select="if ($path eq '/index.xml') then '/' else substring-before($path, '.xml')"/>
            </xsl:value-of>
          </xsl:function>

                  <!-- "?" is illegal in document URIs, but we use it in some REST docs (escaped using "@") -->
                  <xsl:function name="ml:escape-uri">
                    <xsl:param name="external-uri"/>
                    <xsl:sequence select="translate($external-uri,
                                                    '?',
                                                    $questionmark-substitute)"/>  <!-- ?foo=bar   =>   @foo=bar -->
                  </xsl:function>

                  <xsl:function name="ml:unescape-uri">
                    <xsl:param name="doc-uri"/>
                    <xsl:sequence select="translate($doc-uri,
                                                    $questionmark-substitute,
                                                    '?')"/>                       <!-- @foo=bar   =>   ?foo=bar -->
                  </xsl:function>

                          <xsl:variable name="questionmark-substitute" select="'@'"/>


  <!-- overridden in apidoc code -->
  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:sequence select="if ($doc-path eq '/') then '/index.xml' else concat($doc-path, '.xml')"/>
  </xsl:function>

</xsl:stylesheet>
