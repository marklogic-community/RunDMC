<!-- This stylesheet processes an <apidoc:module> document (from the raw docs database)
     and creates a new <api:function> document for each uniquely-named <apidoc:function>
     element it finds. -->
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

  <xdmp:import-module namespace="http://marklogic.com/rundmc/api" href="/apidoc/model/data-access.xqy"/>
  <xdmp:import-module namespace="http://marklogic.com/rundmc/raw-docs-access" href="/apidoc/setup/raw-docs-access.xqy"/>
  <xdmp:import-module namespace="http://marklogic.com/rundmc/util" href="/lib/util-2.xqy"/>

  <!-- Implements some common content fixup rules -->
  <xsl:include href="fixup.xsl"/>

  <xsl:include href="REST-common.xsl"/>

  <xsl:include href="../view/uri-translation.xsl"/>

  <xsl:variable name="REST-complexType-mappings" select="
    if ($api:version eq '5.0') 
    then u:get-doc('/apidoc/config/REST-complexType-mappings.xml')
            /resources/marklogic6/resource
    else if ($api:version eq '6.0') 
    then u:get-doc('/apidoc/config/REST-complexType-mappings.xml')
            /resources/marklogic6/resource
    else u:get-doc('/apidoc/config/REST-complexType-mappings.xml')
            /resources/marklogic7/resource[complexType/@name ne 'woops']" />

  <xsl:template match="/">
<xsl:value-of select="xdmp:log(concat('$api:version: ',$api:version))"/>
                                                              <!-- Function names aren't unique thanks to the way *:polygon()
                                                                   is documented. -->
    <xsl:apply-templates select="apidoc:module/apidoc:function[not(fixup:fullname(.) = preceding-sibling::apidoc:function/fixup:fullname(.))]"/>
  </xsl:template>

  <!-- Extract each function as its own document -->
  <xsl:template match="apidoc:function">
    <xsl:variable name="external-uri">
      <xsl:apply-templates mode="result-path-href" select="."/>
    </xsl:variable>
    <xsl:variable name="internal-uri" select="ml:internal-uri($external-uri)"/>
    <xsl:message>Extracting document: <xsl:value-of select="$internal-uri"/></xsl:message>
    <xsl:result-document href="{$internal-uri}">
      <!-- This wrapper is necessary because the *:polygon() functions
           are each (dubiously) documented as two separate functions so
           that raises the possibility of needing to include two different
           <api:function> elements in the same page. -->
      <api:function-page href="{$external-uri}">
        <!-- For word search purposes -->
        <api:function-name>
          <xsl:value-of select="fixup:fullname(.)"/>
        </api:function-name>
        <xsl:apply-templates mode="fixup" select="../apidoc:function[fixup:fullname(.) eq current()/fixup:fullname(.)]"/>
      </api:function-page>
    </xsl:result-document>
  </xsl:template>

          <!-- This is overridden in REST-common.xsl, for REST docs -->
          <xsl:template mode="result-path-href" match="apidoc:function">
            <xsl:text>/</xsl:text>
            <xsl:value-of select="@lib"/>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="@name"/>
          </xsl:template>


  <!-- Ignore hidden functions -->
  <xsl:template match="apidoc:function[@hidden eq true()]"/>


  <!-- Rename "apidoc" elements to "api" so it's clear which docs we're dealing with later -->
  <xsl:template mode="fixup" match="apidoc:*">
    <xsl:element name="{name()}" namespace="http://marklogic.com/rundmc/api">
      <xsl:apply-templates mode="fixup-content-etc" select="."/>
    </xsl:element>
  </xsl:template>

  <xsl:template mode="fixup-content" match="apidoc:usage[@schema]">
    <xsl:next-match/>
    <xsl:variable name="current-dir" select="string-join(
                                               tokenize(base-uri(.),'/')[position() ne last()],
                                               '/'
                                             )"/>
    <xsl:variable name="schema-uri" select="concat($current-dir, '/', substring-before(@schema,'.xsd'), '.xml')"/>

    <!-- This logic and its attendant assumptions are ported from the docapp code -->
    <xsl:variable name="function-name" select="string(../@name)"/>
    <xsl:variable name="is-REST-resource" select="starts-with($function-name,'/')"/>

    <xsl:variable name="given-name" select="string((@element-name, ../@name)[1])"/>
    <xsl:variable name="complexType-name" select="if ($is-REST-resource) then my:lookup-REST-complexType($function-name)
                                                                         else $given-name"/>

    <xsl:if test="$complexType-name">
      <api:schema-info>
        <xsl:if test="$is-REST-resource">
          <xsl:attribute name="REST-doc">yes</xsl:attribute>
        </xsl:if>
        <xsl:variable name="schema" select="raw:get-doc($schema-uri)/xs:schema"/>
        <xsl:variable name="complexType" select="$schema/xs:complexType[string(@name) eq $complexType-name]"/>

<!--
<xsl:message>
  $function-name: <xsl:value-of select="$function-name"/>
  $schema-uri: <xsl:value-of select="$schema-uri"/>
  $complexType-name: <xsl:value-of select="$complexType-name"/>
  $complexType: <xsl:copy-of select="$complexType"/>
  $schema: <xsl:copy-of select="$schema"/>
</xsl:message>
-->

        <!-- ASSUMPTION: all the element declarations are global; complex type contains only element references -->
        <xsl:apply-templates mode="schema-info" select="$complexType//xs:element"/>

      </api:schema-info>
    </xsl:if>
  </xsl:template>

          <xsl:function name="my:lookup-REST-complexType" as="xs:string?">
            <xsl:param name="resource-name"/>
            <xsl:sequence select="$REST-complexType-mappings[@name eq $resource-name]/complexType/@name/string(.)"/>
          </xsl:function>

          <xsl:template mode="schema-info" match="xs:element">
            <!-- ASSUMPTION: all the element declarations are global -->
            <!-- ASSUMPTION: the schema's default namespace is the same as the target namespace (@ref uses no prefix) -->
            <xsl:variable name="current-ref" select="string(current()/@ref)"/>
            <xsl:variable name="element-decl" select="/xs:schema/xs:element[@name eq $current-ref]"/>

            <xsl:variable name="complexType" select="/xs:schema/xs:complexType[@name eq string($element-decl/@type)]"/>

            <api:element>
              <api:element-name>
                <xsl:value-of select="@ref"/>
              </api:element-name>
              <api:element-description>
                <xsl:value-of select="$element-decl/xs:annotation/xs:documentation"/>
              </api:element-description>
              <xsl:apply-templates mode="#current" select="$complexType//xs:element"/>
            </api:element>
          </xsl:template>


  <!-- Add the namespace URI of the function to the <api:function> result -->
  <xsl:template mode="fixup-add-atts" match="apidoc:function">
    <xsl:attribute name="prefix" select="@lib"/>
    <xsl:attribute name="namespace" select="api:uri-for-lib(@lib)"/>
    <!-- Add the @fullname attribute, which we depend on later. -->
    <xsl:attribute name="fullname" select="fixup:fullname(.)"/>
  </xsl:template>

  <!-- Change the "spell" library to "spell-lib" to disambiguate from the built-in "spell" module -->
  <xsl:template mode="fixup-att-value" match="apidoc:function[@lib eq 'spell' and not(@type eq 'builtin')]/@lib">
    <xsl:text>spell-lib</xsl:text>
  </xsl:template>

  <!-- Similarly, change the "json" library to "json-lib" to disambiguate from the built-in "json" module -->
  <xsl:template mode="fixup-att-value" match="apidoc:function[@lib eq 'json' and not(@type eq 'builtin')]/@lib">
    <xsl:text>json-lib</xsl:text>
  </xsl:template>

  <!-- Change the "rest" library to "rest-lib" because we're reserving the "/REST/" prefix for the REST API docs,
       and I don't want case to be the only thing distinguishing between the two URLs. -->
  <xsl:template mode="fixup-att-value" match="apidoc:function[@lib eq 'rest']/@lib">
    <xsl:text>rest-lib</xsl:text>
  </xsl:template>

  <!-- Change the "manage" (and "XXX" for now...) library to "REST" so the TOC code treats it like a library with that name. -->
  <xsl:template mode="fixup-att-value" match="apidoc:function[@lib = $REST-libs]/@lib">
    <xsl:text>REST</xsl:text>
  </xsl:template>

</xsl:stylesheet>
