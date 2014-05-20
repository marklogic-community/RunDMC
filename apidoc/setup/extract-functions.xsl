<!--
    This stylesheet processes an <apidoc:module> document
    (from the raw docs database)
    and creates a new <api:function> document
    for each uniquely-named <apidoc:function>
    element it finds.

    TODO might be a good candidate for an XQuery port.
-->
<xsl:stylesheet version="2.0"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
                xmlns:ml="http://developer.marklogic.com/site/internal"
                xmlns:my="http://localhost"
                xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
                xmlns:stp="http://marklogic.com/rundmc/api/setup"
                xmlns:u="http://marklogic.com/rundmc/util"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs apidoc raw my u ml">

  <xdmp:import-module
      namespace="http://developer.marklogic.com/site/internal"
      href="/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api"
      href="/apidoc/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/raw-docs-access"
      href="/apidoc/setup/raw-docs-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/setup"
      href="/apidoc/setup/setup.xqm"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/util"
      href="/lib/util-2.xqy"/>

  <xsl:template match="/">
    <!-- create XQuery/XSLT function pages -->
    <xsl:apply-templates select="api:module-extractable-functions(
                                 apidoc:module, ())"/>
    <!-- create (fake) JavaScript function pages -->
    <xsl:if test="number($api:version) ge 8">
      <xsl:apply-templates select="api:module-extractable-functions(
                                   apidoc:module, 'javascript')"/>
    </xsl:if>
  </xsl:template>

  <!-- Ignore hidden functions -->
  <xsl:template match="apidoc:function[@hidden eq true()]"/>

  <!-- Extract each function as its own document -->
  <xsl:template match="apidoc:function">
    <xsl:variable name="mode"
                  select="if (@lib = $api:REST-LIBS) then 'REST' else ()"/>
    <xsl:variable name="external-uri"
                  select="api:external-uri(., $mode)"/>
    <xsl:variable name="internal-uri"
                  select="api:internal-uri($external-uri)"/>
    <xsl:variable name="_LOG"
                  select="stp:debug(
                          'extract-functions.xsl',
                          ('external', $external-uri,
                          'internal', $internal-uri,
                          'mode', $mode))"/>
    <xsl:result-document href="{$internal-uri}">
      <!-- This wrapper is necessary because the *:polygon() functions
           are each (dubiously) documented as two separate functions so
           that raises the possibility of needing to include two different
           <api:function> elements in the same page. -->
      <api:function-page href="{$external-uri}">
        <!-- For word search purposes -->
        <api:function-name>
          <xsl:value-of select="api:fixup-fullname(., ())"/>
        </api:function-name>
        <xsl:copy-of
            select="stp:fixup(
                    ../apidoc:function[
                    api:fixup-fullname(., ())
                    eq api:fixup-fullname(current(), ())])"/>
      </api:function-page>
    </xsl:result-document>
  </xsl:template>

  <!--
      Extract each javascript function as its own document.
      At first these are copies of the XQuery/XSLT function docs,
      but with different URIs.
  -->
  <xsl:template match="apidoc:function[xs:boolean(@is-javascript)]">
    <xsl:variable name="external-uri"
                  select="api:external-uri(., 'javascript')"/>
    <xsl:variable name="internal-uri"
                  select="api:internal-uri($external-uri)"/>
    <xsl:variable name="_LOG"
                  select="stp:debug(
                          'extract-functions.xsl',
                          ('external', $external-uri,
                          'internal', $internal-uri,
                          'mode', 'javascript'))"/>
    <xsl:result-document href="{$internal-uri}">
      <!-- This wrapper is necessary because the *:polygon() functions
           are each (dubiously) documented as two separate functions so
           that raises the possibility of needing to include two different
           <api:function> elements in the same page. -->
      <api:javascript-function-page href="{$external-uri}">
        <!-- For word search purposes -->
        <api:function-name>
          <xsl:value-of select="api:fixup-fullname(., 'javascript')"/>
        </api:function-name>
        <xsl:copy-of
            select="stp:fixup(
                    ../apidoc:function[
                    api:fixup-fullname(., 'javascript')
                    eq api:fixup-fullname(current(), 'javascript')])"/>
      </api:javascript-function-page>
    </xsl:result-document>
  </xsl:template>

</xsl:stylesheet>
