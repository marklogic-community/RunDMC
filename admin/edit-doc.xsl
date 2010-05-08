<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp xhtml">

  <xsl:param name="params"/>

<xsl:output indent="yes"/>

  <xsl:variable name="path" select="$params[@name eq '~doc_uri']"/>

  <xsl:variable name="base-doc" select="xdmp:unquote(string($params[@name eq '~xml_to_edit']))"/>

  <xsl:template match="/">
<foo>
<xsl:copy-of select="$base-doc"/>
    <xsl:apply-templates mode="populate" select="$base-doc/*"/>
</foo>
  </xsl:template>

  <!-- By default, copy everything as is -->
  <xsl:template mode="populate" match="@* | node()" name="default-copy-rule">
    <xsl:param name="content"/>
    <!-- XSLT BUG workaround: The processor behaves badly when I try to give the $content parameter a default value (via content) -->
    <xsl:variable name="real-content">
      <xsl:choose>
        <xsl:when test="$content">
$content supplied:
          <xsl:copy-of select="$content"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="populate-content" select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates mode="populate" select="@*"/>
      <xsl:copy-of select="$real-content"/>
    </xsl:copy>
  </xsl:template>

          <!-- By default, just process children -->
          <xsl:template mode="populate-content" match="*">
            <xsl:apply-templates mode="populate"/>
          </xsl:template>

          <!-- But for fields with names, insert value from the corresponding request parameter -->
          <xsl:template mode="populate-content" match="*[@form:name]">
            <xsl:value-of select="$params[@name eq current()/@form:name]"/>
          </xsl:template>

          <!-- For elements that are children of (part of) a repeating group -->
          <xsl:template mode="populate-content" match="*[@form:group-label]/*[@form:name]" priority="1">
            <xsl:param name="position" tunnel="yes"/>
            <PROCESSED position="{$position}">
            <xsl:value-of select="$params[@name eq concat(current()/@form:name,'[',$position,']')]"/>
            </PROCESSED>
          </xsl:template>


  <!-- For repeating elements (not repeating groups) -->
  <xsl:template mode="populate" match="*[@form:name and (@form:repeating eq 'yes')]">
    <xsl:variable name="prefix" select="concat(@form:name, '[')"/>
    <xsl:variable name="element" select="."/>
    <!-- Create one for each parameter that was submitted -->
    <xsl:for-each select="$params[starts-with(@name, $prefix)]">
      <!-- Sort by the positional indicator [1], [2], etc. -->
      <xsl:sort select="form:extract-position(@name)" data-type="number"/>
      <xsl:variable name="param" select="."/>
      <xsl:for-each select="$element">
        <xsl:call-template name="default-copy-rule">
          <xsl:with-param name="content" select="string($param)"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- For elements that represent a repeating group -->
  <xsl:template mode="populate" match="*[@form:group-label]">
    <!-- We are going to use the first child in this group as the prefix to look for among the request parameters -->
    <xsl:variable name="prefix" select="concat(*[1]/@form:name, '[')"/>
    <xsl:variable name="element" select="."/>
    <!-- Create one for each first parameter that was submitted -->
    <xsl:for-each select="$params[starts-with(@name, $prefix)]">
      <!-- Sort by the positional indicator [1], [2], etc. -->
      <xsl:sort select="form:extract-position(@name)" data-type="number"/>
      <xsl:variable name="param" select="."/>
      <found param="{@name}">
      <xsl:for-each select="$element">
        <xsl:call-template name="default-copy-rule">
          <xsl:with-param name="content">
            <!-- Process the content, passing the current positional context along -->
            <xsl:apply-templates mode="populate" select="*">
              <xsl:with-param name="position" select="form:extract-position($param/@name)" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
      </found>
    </xsl:for-each>
  </xsl:template>

<xsl:template mode="test" match="*">
  <xsl:apply-templates mode="populate" select="."/>
</xsl:template>

  <xsl:function name="form:extract-position">
    <xsl:param name="string"/>
    <xsl:sequence select="number(substring-before(substring-after($string, '['), ']'))"/>
  </xsl:function>
  
  <!-- Strip out the repeated items; we're replacing them all with values from the parameters -->
  <xsl:template mode="populate" match="*[@form:subsequent-item]"/>

</xsl:stylesheet>
