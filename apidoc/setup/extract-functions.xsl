<!--
    This stylesheet processes an <apidoc:module> document
    (from the raw docs database)
    and creates a new <api:function> document
    for each uniquely-named <apidoc:function>
    element it finds.

    TODO might be a good candidate for an XQuery port.
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:fixup="http://marklogic.com/rundmc/api/fixup"
                xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
                xmlns:my="http://localhost"
                xmlns:u="http://marklogic.com/rundmc/util"
                xmlns:ml="http://developer.marklogic.com/site/internal"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs apidoc fixup raw my u ml">

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
      namespace="http://marklogic.com/rundmc/util"
      href="/lib/util-2.xqy"/>

  <!-- Implements some common content fixup rules -->
  <xsl:include href="fixup.xsl"/>

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
                  select="xdmp:log(concat(
                          'Extracting document:',
                          ' external=', $external-uri,
                          ' internal=', $internal-uri,
                          ' mode=', $mode), 'debug')"/>
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
        <xsl:apply-templates
            mode="fixup"
            select="../apidoc:function[
                    api:fixup-fullname(., ()) eq current()
                    /api:fixup-fullname(., ())]"/>
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
                  select="xdmp:log(concat(
                          'Extracting document:',
                          ' external=', $external-uri,
                          ' internal=', $internal-uri,
                          ' mode=javascript'))"/>
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
        <xsl:apply-templates
            mode="fixup"
            select="../apidoc:function[
                      api:fixup-fullname(., 'javascript') eq current()
                    /api:fixup-fullname(., 'javascript')]"/>
      </api:javascript-function-page>
    </xsl:result-document>
  </xsl:template>

  <!-- Rename "apidoc" elements to "api" so it's clear which docs
       we're dealing with later -->
  <xsl:template mode="fixup" match="apidoc:*">
    <xsl:element name="{local-name()}"
                 namespace="http://marklogic.com/rundmc/api">
      <xsl:apply-templates mode="fixup-content-etc" select="."/>
    </xsl:element>
  </xsl:template>

  <xsl:template mode="fixup-content" match="apidoc:usage[@schema]">
    <xsl:variable
        name="current-dir"
        select="string-join(
                tokenize(base-uri(.),'/')[position() ne last()], '/')"/>
    <xsl:variable
        name="schema-uri"
        select="concat($current-dir, '/',
                substring-before(@schema,'.xsd'), '.xml')"/>

    <!-- This logic and its attendant assumptions are ported from the
         docapp code -->
    <xsl:variable name="function-name" select="string(../@name)"/>
    <xsl:variable name="is-REST-resource"
                  select="starts-with($function-name,'/')"/>

    <xsl:variable name="given-name"
                  select="string((@element-name, ../@name)[1])"/>
    <xsl:variable name="complexType-name"
                  select="if ($is-REST-resource and not(@element-name))
                          then api:lookup-REST-complexType($function-name)
                          else $given-name"/>
    <xsl:variable
        name="print-intro-value"
        select="if (@print-intro) then string(@print-intro) else 'true'"/>

    <xsl:if test="$complexType-name">
      <xsl:apply-templates mode="fixup" />
      <api:schema-info>
        <xsl:if test="$is-REST-resource">
          <xsl:attribute name="REST-doc">yes</xsl:attribute>
          <xsl:attribute name="print-intro">
            <xsl:value-of
                select="$print-intro-value"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:variable name="schema"
                      select="raw:get-doc($schema-uri)/xs:schema"/>
        <xsl:variable name="complexType"
                      select="$schema/xs:complexType
                              [string(@name) eq $complexType-name]"/>

        <!-- ASSUMPTION: all the element declarations are global; complex
             type contains only element references -->
        <xsl:apply-templates mode="schema-info"
                             select="$complexType//xs:element"/>

      </api:schema-info>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="schema-info" match="xs:element">
    <!-- ASSUMPTION: all the element declarations are global -->
    <!-- ASSUMPTION: the schema's default namespace is the same as the
         target namespace (@ref uses no prefix) -->
    <xsl:variable name="current-ref" select="string(current()/@ref)"/>
    <xsl:variable name="element-decl"
                  select="/xs:schema/xs:element[@name eq $current-ref]"/>

    <xsl:variable name="complexType"
                  select="/xs:schema/xs:complexType
                          [@name eq string($element-decl/@type)]"/>

    <api:element>
      <api:element-name>
        <xsl:value-of select="@ref"/>
      </api:element-name>
      <api:element-description>
        <xsl:value-of select="$element-decl/xs:annotation
                              /xs:documentation"/>
      </api:element-description>
      <xsl:apply-templates mode="#current"
                           select="$complexType//xs:element"/>
    </api:element>
  </xsl:template>

  <!-- Add the namespace URI of the function to the <api:function> result -->
  <xsl:template mode="fixup-add-atts" match="apidoc:function">
    <xsl:attribute name="prefix" select="@lib"/>
    <xsl:attribute name="namespace" select="api:uri-for-lib(@lib)"/>
    <!--
        Add the @fullname attribute, which we depend on later.
        This depends on the @is-javascript attribute,
        which is faked in api:function-fake-javascript.
    -->
    <xsl:attribute name="fullname"
                   select="api:fixup-fullname(
                           .,
                           if (starts-with(@name, '/')) then 'REST'
                           else if (@is-javascript) then 'javascript'
                           else ())"/>
  </xsl:template>

</xsl:stylesheet>
