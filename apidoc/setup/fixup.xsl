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

  <!-- Change, e.g., #xdmp:tidy to /xdmp:tidy -->
  <!-- ASSUMPTION: If the fragment id contains a colon, then this is a link to
       a function page -->
  <xsl:template mode="fixup-att-value"
                match="a/@href[starts-with(.,'#') and contains(.,':')]"
                priority="3">
    <xsl:variable name="result"
                  select="translate(.,'#','/')"/>
    <xsl:value-of select="api:fixup-trace(., $result)"/>
  </xsl:template>

  <xsl:template mode="fixup-att-value"
                match="@href[starts-with(.,'#') and contains(.,':')]"
                priority="3">
    <xsl:variable name="result"
                  select="translate(.,'#','/')"/>
    <xsl:value-of select="api:fixup-trace(., $result)"/>
  </xsl:template>

  <!-- Otherwise, fragment links point to a location within the same <apidoc:module> document -->
  <xsl:template mode="fixup-att-value"
                match="a/@href[starts-with(.,'#')]"
                priority="2">
    <xsl:variable name="relevant-function"
                  select="/apidoc:module/apidoc:function
                          [.//*/@id[. eq substring-after(current(),'#')]]"/>
    <xsl:variable name="result" as="xs:string">
      <xsl:value-of>
        <!-- If we're on a different page, then insert the link to the targeted page -->
        <xsl:if test="not(ancestor::apidoc:function is $relevant-function)">
          <xsl:choose>
            <!-- REST URLs are written differently than function URLs -->
            <xsl:when test="$relevant-function/@lib = $api:REST-LIBS">
              <!-- path to resource page -->
              <xsl:value-of
                  select="$relevant-function/api:REST-fullname-to-external-uri(
                          api:fixup-fullname(., 'REST'))"/>
            </xsl:when>
            <!-- regular function page -->
            <xsl:otherwise>
              <xsl:text>/</xsl:text>
              <!--
                  path to function page TODO add mode when javascript
              -->
              <xsl:value-of
                  select="$relevant-function/api:fixup-fullname(., ())"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
        <!-- fragment id -->
        <xsl:value-of select="."/>
      </xsl:value-of>
    </xsl:variable>
    <xsl:value-of select="api:fixup-trace(.,$result)"/>
  </xsl:template>

  <!-- If it's an absolute path (e.g., http://w3.org), then don't change the value -->
  <xsl:template mode="fixup-att-value" match="a/@href[contains(.,'://')]" priority="1">
    <xsl:variable name="result" select="string(.)"/>
    <xsl:value-of select="api:fixup-trace(.,$result)"/>
  </xsl:template>

  <!-- Otherwise, assume it's a function page (with an optional fragment id);
       in that case, we need only prepend a slash -->
  <xsl:template mode="fixup-att-value" match="a/@href">
    <xsl:variable name="result" select="concat('/', .)"/>
    <xsl:value-of select="api:fixup-trace(.,$result)"/>
  </xsl:template>

  <!-- Bad, bad -->
  <xsl:template mode="fixup-att-value"
                match="a/@href[. eq 'apidocs.xqy?fname=UpdateBuiltins#xdmp:document-delete']"
                priority=".8">
    <xsl:variable name="result" select="'/xdmp:document-delete'"/>
    <xsl:value-of select="api:fixup-trace(.,$result)"/>
  </xsl:template>
  <xsl:template mode="fixup-att-value"
                match="a/@href[. =
                       ('apidocs.xqy?fname=cts:query Constructors',
                       'SearchBuiltins&amp;sub=cts:query Constructors')]"
                priority=".8">
    <xsl:variable name="result" select="'/cts/constructors'"/>
    <xsl:text>/cts/constructors</xsl:text>
    <!-- as we configured in ../config/category-mappings.xml -->
  </xsl:template>
  <xsl:template mode="fixup-att-value"
                match="@href[. =
                       ('apidocs.xqy?fname=cts:query Constructors',
                       'SearchBuiltins&amp;sub=cts:query Constructors')]"
                priority=".8">
    <xsl:variable name="result" select="'/cts/constructors'"/>
    <xsl:text>/cts/constructors</xsl:text>
    <!-- as we configured in ../config/category-mappings.xml -->
  </xsl:template>

  <!-- Fixup Linkerator links
       Change "#display.xqy&fname=http://pubs/5.1doc/xml/admin/foo.xml"
       to "/guide/admin/foo"
  -->
  <xsl:template mode="fixup-att-value"
                match="a/@href[starts-with(.,'#display.xqy?fname=')]" priority="4">
    <xsl:variable name="anchor" select="replace(substring-after(., '.xml'),
                                        '%23', '#id_')"/>
    <xsl:variable name="result"
                  select="stp:fix-guide-names(concat('/guide',
                          substring-before(substring-after(.,
                          'doc/xml'), '.xml'),
                          $anchor), 1)"/>
    <xsl:value-of select="api:fixup-trace(.,$result)"/>
  </xsl:template>
  <!-- End Linkerator fixup -->

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
    <xsl:attribute name="{name(.)}" namespace="{namespace-uri(.)}">
      <xsl:apply-templates mode="fixup-att-value" select="."/>
    </xsl:attribute>
  </xsl:template>

  <!-- By default, just use the given value -->
  <xsl:template mode="fixup-att-value" match="@*">
    <xsl:value-of select="."/>
  </xsl:template>

</xsl:stylesheet>
