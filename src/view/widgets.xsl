<!-- This stylesheet implements the <ml:widgets/> custom tag
     for inserting widgets into the site's sidebar. The widget
     configuration file is consulted to determine which widgets
     should be displayed on the current page.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:u                ="http://marklogic.com/rundmc/util"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xdmp:import-module href="../lib/util-2.xqy" namespace="http://marklogic.com/rundmc/util"/>

  <xsl:variable name="widget-config"  select="u:get-doc('/config/widgets.xml')"/>

  <xsl:variable name="current-page" select="$navigation//page[@href eq $external-uri]"/>

  <xsl:template match="xhtml:div[@id eq 'content']/@ml:class">
    <xsl:variable name="last-widget" select="$widget-config/widgets/widget[*[ml:matches-current-page(.)]][last()]"/>
    <!-- If the last widget is a "feature widget", we need to accordingly babysit the CSS class -->
    <xsl:if test="$last-widget/@feature">
      <xsl:attribute name="class">sub_special</xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="widgets">
    <xsl:apply-templates mode="widget" select="$widget-config/widgets/widget[*[ml:matches-current-page(.)]]"/>
  </xsl:template>

  <xsl:template mode="widget" match="widget[@feature]">
    <div class="section special">
      <div class="head">
        <h2>
          <xsl:apply-templates select="u:get-doc(@feature)/feature/title/node()"/>
        </h2>
      </div>
      <div class="body">
        <xsl:apply-templates mode="feature-content" select="u:get-doc(@feature)/feature/(* except title)">
          <xsl:with-param name="is-widget" select="true()" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
    </div>
  </xsl:template>

  <xsl:template mode="widget" match="widget">
    <section class="widget" id="{@id}">
      <xsl:if test="not(empty(@href)) and exists(u:get-doc(@href)/widget/@class)">
        <xsl:attribute name="class">
          <xsl:value-of select="concat('section ', u:get-doc(@href)/widget/@class)"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates mode="widget-content" select="."/>
    </section>
  </xsl:template>

  <xsl:template mode="widget-content" match="widget">
    <xsl:apply-templates select="u:get-doc(@href)/widget/node()"/>
  </xsl:template>

  <xsl:template mode="widget-content" match="widget[@xquery]">
    <xsl:copy-of select="ml:xquery-widget(@xquery)"/>
  </xsl:template>

  <xsl:template mode="widget-content" match="widget[@xslt]">
    <xsl:copy-of select="ml:xslt-widget(@xslt)"/>
  </xsl:template>


  <xsl:function name="ml:matches-current-page" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:apply-templates mode="matches-current-page" select="$element"/>
  </xsl:function>

  <xsl:template mode="matches-current-page" match="page[@href]">
    <xsl:sequence select="@href eq $external-uri"/>
  </xsl:template>

  <xsl:template mode="matches-current-page" match="page-tree">
    <xsl:sequence select="starts-with($external-uri, @root)"/>
  </xsl:template>

  <xsl:template mode="matches-current-page" match="page-children">
    <xsl:sequence select="@parent = $current-page/ancestor::page/@href"/>
  </xsl:template>

  <xsl:template mode="matches-current-page" match="*">
    <xsl:sequence select="node-name($content/*) eq node-name(.)"/>
  </xsl:template>

</xsl:stylesheet>
