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

  <xsl:include href="form.xsl"/>
  <xsl:include href="tag-library.xsl"/>

  <xsl:variable name="template"   select="u:get-doc('/admin/config/template.xhtml')"/>
  <xsl:variable name="navigation" select="u:get-doc('/admin/config/navigation.xml')"/>

  <!-- Make everything a "main page" -->
  <xsl:template mode="body-class" match="*">main_page</xsl:template>

  <!-- *Do* include breadcrumbs on the home page -->
  <xsl:template mode="breadcrumbs" match="*">
    <xsl:call-template name="breadcrumbs-impl">
      <xsl:with-param name="site-name" select="'Developer Community: Content Management'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Don't display "Home" -->
  <xsl:template mode="breadcrumb-display" match="page[@href eq '/']"/>

  <!-- Account for "/admin" prefix in internal/external URI mappings -->
  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:variable name="doc-path" select="base-uri($node)"/>
    <xsl:sequence select="if ($doc-path eq '/admin/index.xml') then '/' else substring-before(substring-after($doc-path,'/admin'), '.xml')"/>
  </xsl:function>

  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:sequence select="if ($doc-path eq '/') then '/admin/index.xml' else concat('/admin', $doc-path, '.xml')"/>
  </xsl:function>

  <!-- Don't ever add any special CSS classes -->
  <xsl:template mode="body-class-extra" match="*"/>

  <!-- Always disable comments in the Admin UI -->
  <xsl:template mode="comment-section" match="*"/>

</xsl:stylesheet>
