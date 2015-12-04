<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="h xs"
                version="2.0">

<xsl:template match="/">
  <article>
    <xsl:apply-templates select="//h:section[@id = 'page_content']"/>
  </article>
</xsl:template>

<xsl:template match="h:section">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="h:script|h:noscript|h:input">
  <!-- suppress -->
</xsl:template>

<xsl:template match="h:div[@id='comments']">
  <!-- suppress -->
</xsl:template>

<xsl:template match="h:div[@id='copyright']">
  <!-- suppress -->
</xsl:template>

<xsl:template match="h:div[@class='api-function-links']">
  <!-- suppress -->
</xsl:template>

<xsl:template match="h:a[@href='?print=yes']" priority="100">
  <!-- suppress -->
</xsl:template>

<xsl:template match="h:h1">
  <h3>
    <xsl:apply-templates select="@*,node()"/>
  </h3>
</xsl:template>

<xsl:template match="h:h2">
  <h4>
    <xsl:apply-templates select="@*,node()"/>
  </h4>
</xsl:template>

<xsl:template match="h:h3">
  <h5>
    <xsl:apply-templates select="@*,node()"/>
  </h5>
</xsl:template>

<xsl:template match="h:h1/h:a" priority="100">
  <xsl:value-of select="."/>
</xsl:template>

<xsl:template match="h:a[starts-with(@href, '#')]">
  <a href="#{generate-id(/*)}.{substring-after(@href,'#')}">
    <xsl:copy-of select="@* except @href"/>
    <xsl:apply-templates/>
  </a>
</xsl:template>

<xsl:template match="h:a[starts-with(@href, './')]">
  <a href="#{substring(@href,3)}">
    <xsl:copy-of select="@* except @href"/>
    <xsl:apply-templates/>
  </a>
</xsl:template>

<xsl:template match="h:a[starts-with(@href, '/js/')]">
  <a href="#sec.{substring(@href,5)}">
    <xsl:copy-of select="@* except @href"/>
    <xsl:apply-templates/>
  </a>
</xsl:template>

<xsl:template match="h:a[@name]">
  <a name="{generate-id(/*)}.{@name}">
    <xsl:copy-of select="@* except @name"/>
    <xsl:apply-templates/>
  </a>
</xsl:template>

<xsl:template match="element()">
  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="@id">
  <xsl:attribute name="id">
    <xsl:value-of select="concat(generate-id(/*), '.', .)"/>
  </xsl:attribute>
</xsl:template>

<xsl:template match="attribute()|text()|comment()|processing-instruction()">
  <xsl:copy/>
</xsl:template>

</xsl:stylesheet>
