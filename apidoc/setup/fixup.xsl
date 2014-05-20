<!--
    This stylesheet is used by both the list page generator
    and the function extraction scripts. Behavior is to
    copy everything as is, with certain exceptions.
    Including stylesheets may augment the rules.
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:fixup="http://marklogic.com/rundmc/api/fixup"
                xmlns:stp="http://marklogic.com/rundmc/api/setup"
                xpath-default-namespace="http://www.w3.org/1999/xhtml"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs apidoc fixup api">

  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/setup"
      href="setup.xqm"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api"
      href="/apidoc/model/data-access.xqy"/>

  <!--
      Everything below is boilerplate,
      supplying the default behavior and hooks for overriding it.
  -->

  <!-- By default, copy child nodes unchanged -->
  <xsl:template mode="fixup" match="node()">
    <xsl:copy>
      <!-- For elements, fixup content and attributes -->
      <xsl:apply-templates mode="fixup-content-etc" select="."/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="fixup-content-etc" match="*">
    <!-- existing attributes -->
    <xsl:apply-templates mode="fixup" select="@*"/>
    <!-- additional attributes -->
    <xsl:apply-templates mode="fixup-add-atts" select="."/>
    <!-- content -->
    <xsl:apply-templates mode="fixup-content" select="."/>
  </xsl:template>

  <!-- By default, don't add any attributes -->
  <xsl:template mode="fixup-add-atts" match="*"/>

  <!-- By default, process children -->
  <xsl:template mode="fixup-content" match="*">
    <xsl:apply-templates mode="fixup"/>
  </xsl:template>

  <!-- Replicate attributes, with a possibly different value -->
  <xsl:template mode="fixup" match="@*">
    <xsl:copy-of select="stp:fixup-attribute(.)"/>
  </xsl:template>

</xsl:stylesheet>
