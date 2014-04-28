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

  <xdmp:import-module
      namespace="http://marklogic.com/xdmp/admin/admin-forms"
      href="/MarkLogic/admin/admin-forms.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api"
      href="/apidoc/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/util"
      href="/lib/util-2.xqy"/>

  <xsl:variable name="help-root-href"
                select="'/admin-help'"/>

  <xsl:variable name="help-config"
                select="u:get-doc('/apidoc/config/help-config.xml')/help"/>

  <!-- default value provided just for testing purposes -->
  <xsl:variable name="xsd-dir"
                select="xdmp:get-request-field(
                        'help-xsd-dir', '/Users/elenz/Desktop/Config/6.0')"/>

  <xsl:variable name="xsd-docs"
                select="for $dir in xdmp:filesystem-directory($xsd-dir)/*:entry[
                        *:type eq 'file']
                        [*:pathname/ends-with(.,'.xsd')]
                        return xdmp:document-get($dir/*:pathname)"/>

  <xsl:template mode="help-toc" match="/">
    <!--
        For error-checking only
        helps propagate a more useful error: directory not found.
    -->
    <xsl:value-of select="if ($xsd-docs) then () else ()"/>

    <node display="{$help-config/@display}"
          href="{$help-root-href}"
          id="HelpTOC"
          admin-help-page="yes">
      <xsl:apply-templates mode="help-node-open-att" select="."/>
      <title>Admin Interface Help Pages</title>
      <content auto-help-list="yes"/>
      <xsl:apply-templates mode="#current" select="$help-config/*"/>
    </node>
  </xsl:template>

  <!-- Ignore sections that were added in a later server version -->
  <xsl:template mode="help-toc"
                match="*[number(@added-in) gt number($api:version)]"/>

  <xsl:template mode="help-toc" match="*">
    <xsl:variable name="element-decl"
                  select="help:element-decl(.)"/>
    <xsl:variable name="exclusion-list"
                  select="tokenize(normalize-space(@exclude),' '),
                          if (@starting-with) then help:not-prefixed-names(.)
                          else if (@auto-exclude)  then help:auto-exclude(.)
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
                      select="root(help:element-decl($proxy-element))/*"/>
        <xsl:copy-of
            select="af:displayHelp($schema-element,
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
                          else help:extract-title($help-content)"/>
    <node display="{@display}"
          href="{help:path(.)}"
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

  <!-- collapsed by default -->
  <xsl:template mode="help-node-open-att" match="*"/>
  <!-- top two Help TOC levels pre-expanded would be "/*|/*/*" -->
  <xsl:template mode="help-node-open-att" match="NOTHING">
    <xsl:attribute name="open" select="'yes'"/>
  </xsl:template>


  <xsl:template mode="help-toc" match="repeat">
    <xsl:apply-templates mode="#current" select="help:resolve-repeat(.)"/>
  </xsl:template>

  <xsl:template mode="help-toc" match="container">
    <node display="{@display}">
      <xsl:apply-templates mode="#current"/>
    </node>
  </xsl:template>

  <xsl:function name="help:element-decl">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence
        select="$xsd-docs//xs:element[@name][
                QName(/*/@targetNamespace,@name) eq node-name($e)]"/>
  </xsl:function>

  <xsl:function name="help:extract-title">
    <xsl:param name="content"/>
    <!-- sometimes the source uses XHTML, sometimes not (e.g., x509.xsd) -->
    <xsl:sequence
        select="($content//*:span[@class eq 'help-text'])[1]/normalize-space(.)"/>
  </xsl:function>


  <xsl:function name="help:path">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="help-name" as="xs:string?">
      <xsl:apply-templates mode="help-name" select="$e"/>
    </xsl:variable>
    <xsl:sequence select="concat(
                          $help-root-href,
                          if ($help-name) then concat('/', $help-name)
                          else ())"/>
  </xsl:function>

  <!-- Use an explicit override, if present -->
  <xsl:template mode="help-name" match="*[@url-name]">
    <xsl:value-of select="@url-name"/>
  </xsl:template>

  <!-- Otherwise, just use the local name -->
  <xsl:template mode="help-name" match="*">
    <xsl:value-of select="local-name()"/>
  </xsl:template>

  <xsl:function name="help:resolve-repeat">
    <xsl:param name="e" as="element(repeat)"/>
    <xsl:sequence
        select="root($e)//*[
                @id eq $e/@idref
                or node-name(.) eq resolve-QName($e/@name,$e)]"/>
  </xsl:function>

  <xsl:function name="help:auto-exclude">
    <xsl:param name="e" as="element()"/>
    <!-- For each of the other applicable elements in the same namespace -->
    <xsl:for-each select="root($e)//*[namespace-uri(.) eq namespace-uri($e)]
                          [not(. is $e)]
                          [not(@added-in)
                           or number(@added-in) le number($api:version)]">
      <xsl:variable name="this-name" select="local-name(.)"/>
      <!--
          Automatically exclude this name, its plural forms,
          and whatever prefixed names it might stand for.
      -->
      <xsl:sequence select="help:prefixed-names(.),
                            $this-name,
                            concat($this-name,'s'),
                            concat($this-name,'es')"/>
    </xsl:for-each>
  </xsl:function>

  <!-- All the child element names having the given prefix -->
  <xsl:function name="help:prefixed-names">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence
        select="if ($e/@starting-with) then help:option-names(
                $e)[starts-with(.,$e/@starting-with)]
                else ()"/>
  </xsl:function>

  <!-- All the child element names *not* having the given prefix -->
  <xsl:function name="help:not-prefixed-names">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence
        select="help:option-names($e)[not(starts-with(.,$e/@starting-with))]"/>
  </xsl:function>

  <!-- Look in the XSD to grab the list of child element names -->
  <xsl:function name="help:option-names">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="decl" select="help:element-decl($e)"/>
    <xsl:variable name="complexType"
                  select="root($decl)/*/xs:complexType[
                          @name/resolve-QName(string(.),..)
                          eq $decl/@type/resolve-QName(string(.),..)]"/>
    <xsl:sequence
        select="$complexType//xs:element/@ref/local-name-from-QName(
                resolve-QName(string(.),..))"/>
  </xsl:function>

  <!-- By default, copy -->
  <xsl:template mode="convert-help-content" match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@* | node()"/>
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
