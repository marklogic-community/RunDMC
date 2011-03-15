<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:import href="../../view/page.xsl"/>

  <xsl:include href="tag-library.xsl"/>

  <xsl:variable name="template"   select="u:get-doc('/apidoc/config/template.xhtml')"/>

  <!-- Make everything a "main page" -->
  <xsl:template mode="body-class" match="*">main_page</xsl:template>


  <!-- Account for "/apidoc" prefix in internal/external URI mappings -->
  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:variable name="doc-path" select="base-uri($node)"/>
    <xsl:sequence select="if ($doc-path eq '/apidoc/index.xml') then '/' else substring-before(substring-after($doc-path,'/apidoc'), '.xml')"/>
  </xsl:function>

  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:sequence select="if ($doc-path eq '/') then '/apidoc/index.xml' else concat('/apidoc', $doc-path, '.xml')"/>
  </xsl:function>

  <!-- Don't ever add any special CSS classes -->
  <xsl:template mode="body-class-extra" match="*"/>

</xsl:stylesheet>
