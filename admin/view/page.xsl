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

  <xsl:variable name="template"
                select="u:get-doc('/admin/config/template.xhtml')"/>
  <xsl:variable name="navigation"
                select="u:get-doc('/admin/config/navigation.xml')"/>


  <!-- Set state. -->
  <xsl:template match="/">
    <xsl:value-of
        select="xdmp:set($ml:ADMIN, true())"/>
    <xsl:next-match/>
  </xsl:template>

  <!-- Make everything a "main page" -->
  <xsl:template mode="body-class" match="*">main_page</xsl:template>

  <!-- Don't add a server prefix to the top nav links -->
  <xsl:template mode="top-nav-server-prefix" match="page"/>

  <!-- *Do* include breadcrumbs on the home page -->
  <xsl:template mode="breadcrumbs" match="*">
    <xsl:call-template name="breadcrumbs-impl">
      <xsl:with-param name="site-name"
                      select="'Developer Community: Content Management'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Don't display "Home" -->
  <xsl:template mode="breadcrumb-display" match="page[@href eq '/']"/>

  <!-- Don't ever add any special CSS classes -->
  <xsl:template mode="body-class-extra" match="*"/>

  <!-- Always disable comments in the Admin UI -->
  <xsl:template mode="comment-section" match="*"/>

</xsl:stylesheet>
