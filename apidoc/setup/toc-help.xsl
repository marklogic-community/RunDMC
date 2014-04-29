<!--
    Some of the schema files (like x509.xsd) don't consistently declare
    the default XHTML namespace on <admin:help>. Downstream, make-list-pages.xsl
    forces everything to be in XHTML.
-->
<xsl:stylesheet version="2.0"
                xmlns:af="http://marklogic.com/xdmp/admin/admin-forms"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:help="http://marklogic.com/rundmc/apidoc/help"
                xmlns:toc="http://marklogic.com/rundmc/api/toc"
                xmlns:u="http://marklogic.com/rundmc/util"
                xmlns:x="http://www.w3.org/1999/xhtml"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://marklogic.com/rundmc/api/toc"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs u help af api">

  <!--
      This code relies on undocumented and unsupported functions
      found in the MarkLogic admin UI code (af:).
  -->
  <xdmp:import-module
      namespace="http://marklogic.com/xdmp/admin/admin-forms"
      href="/MarkLogic/admin/admin-forms.xqy"/>

  <!-- The importer of this xsl should import data-access.xqm -->
  <!-- The importer of this xsl should import toc.xqm -->

  <!-- TODO turn into a function call -->
  <!-- collapsed by default -->
  <xsl:template mode="help-node-open-att" match="*"/>
  <!-- top two Help TOC levels pre-expanded would be "/*|/*/*" -->
  <xsl:template mode="help-node-open-att" match="NOTHING">
    <xsl:attribute name="open" select="'yes'"/>
  </xsl:template>

  <xsl:template mode="help-toc" match="/">
    <!--
        For error-checking only
        helps propagate a more useful error: directory not found.
    -->
    <xsl:value-of select="if ($toc:XSD-DOCS) then () else ()"/>

    <node display="{$toc:HELP-CONFIG/@display}"
          href="{$toc:HELP-ROOT-HREF}"
          id="HelpTOC"
          admin-help-page="yes">
      <xsl:apply-templates mode="help-node-open-att" select="."/>
      <title>Admin Interface Help Pages</title>
      <content auto-help-list="yes"/>
      <xsl:apply-templates mode="#current" select="$toc:HELP-CONFIG/*"/>
    </node>
  </xsl:template>

  <!-- Ignore sections that were added in a later server version -->
  <xsl:template mode="help-toc"
                match="*[number(@added-in) gt number($api:version)]"/>

  <xsl:template mode="help-toc" match="*">
    <xsl:variable name="element-decl"
                  select="toc:help-element-decl($toc:XSD-DOCS, .)"/>
    <xsl:variable name="exclusion-list"
                  select="tokenize(normalize-space(@exclude),' '),
                          if (@starting-with) then toc:help-not-prefixed-names($toc:XSD-DOCS, .)
                          else if (@auto-exclude) then toc:help-auto-exclude($toc:XSD-DOCS, .)
                          else ()"/>
    <xsl:variable name="line-after-list"
                  select="tokenize(normalize-space(@line-after),' ')"/>
    <xsl:variable name="help-content">
      <xsl:copy-of
          select="af:displayHelp(
                  root($element-decl)/*,                            (: $schemaroot    :)
                  local-name(.),                                    (: $name          :)
                  if (@help-position/number(.) eq 2) then 2 else 1, (: $multiple-uses :)
                  $exclusion-list,                                  (: $excluded      :)
                  $line-after-list,                                 (: $line-after    :)
                  if (@append) then false() else true()             (: $print-buttons :)
                  )"/>
      <xsl:if test="@append">
        <xsl:variable name="proxy-element" as="element()">
          <xsl:element name="{@append}"
                       namespace="{namespace-uri-from-QName(
                                  resolve-QName(@append,.))}"/>
        </xsl:variable>
        <xsl:variable name="schema-element"
                      select="root(
                              toc:help-element-decl(
                              $toc:XSD-DOCS, $proxy-element))/*"/>
        <xsl:copy-of
            select="af:displayHelp(
                    $schema-element,
                    local-name($proxy-element),
                    if (@append-help-position/number(.) eq 2) then 2 else 1,
                    $exclusion-list,
                    $line-after-list,
                    true())"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="help-content-except-title">
      <!-- Copy everything after the second <hr> -->
      <!-- ASSUMPTION: the title of the page appears in between two <hr> elements at the beginning -->
      <!-- one page (flexrep-domain) is missing the second <hr> -->
      <xsl:copy-of
          select="if ($help-content/*:hr[2])
                  then $help-content/*:hr[2]/following-sibling::node()
                  else $help-content/*:span[1]/following-sibling::node()"/>
    </xsl:variable>
    <xsl:variable name="help-content-converted">
      <xsl:apply-templates mode="convert-help-content"
                           select="$help-content-except-title"/>
    </xsl:variable>
    <xsl:variable name="title"
                  select="if (@content-title)
                          then @content-title
                          else toc:help-extract-title($help-content)"/>
    <node display="{@display}"
          href="{toc:help-path($toc:HELP-ROOT-HREF, .)}"
          admin-help-page="yes">
      <xsl:apply-templates mode="help-node-open-att" select="."/>
      <title>
        <xsl:value-of select="$title"/>
      </title>
      <content>
        <xsl:copy-of
            select="if (@show-only-the-list) then ($help-content-converted//*:ul)[1]
                    else  $help-content-converted"/>
      </content>
      <xsl:apply-templates mode="#current"/>
    </node>
  </xsl:template>

  <xsl:template mode="help-toc" match="repeat">
    <xsl:apply-templates mode="#current"
                         select="toc:help-resolve-repeat(.)"/>
  </xsl:template>

  <xsl:template mode="help-toc" match="container">
    <node display="{@display}">
      <xsl:apply-templates mode="#current"/>
    </node>
  </xsl:template>

  <!-- By default, copy -->
  <xsl:template mode="convert-help-content"
                match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current"
                           select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Convert hard-coded color spans into <strong> tags -->
  <!-- string() avoids a failed atomization attempt, at least in some builds -->
  <xsl:template mode="convert-help-content"
                match="*:span[contains(string(@style),'color:')]">
    <strong class="configOption">
      <xsl:apply-templates mode="#current"/>
    </strong>
  </xsl:template>

  <!-- Rewrite image URLs -->
  <xsl:template mode="convert-help-content" match="*:img/@src">
    <xsl:attribute name="src" select="concat('/apidoc/images/admin-help/',.)"/>
    <xsl:attribute name="class" select="'adminHelp'"/>
  </xsl:template>

</xsl:stylesheet>
