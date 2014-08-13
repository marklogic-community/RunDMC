<!--
    Stylesheet that's invoked for rendering every page in apidocs.
    Overrides behavior of /view/page.xsl.
-->
<xsl:stylesheet version="2.0"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
                xmlns:guide="http://marklogic.com/rundmc/api/guide"
                xmlns:ml="http://developer.marklogic.com/site/internal"
                xmlns:srv="http://marklogic.com/rundmc/server-urls"
                xmlns:u="http://marklogic.com/rundmc/util"
                xmlns:v="http://marklogic.com/rundmc/api/view"
                xmlns:x="http://www.w3.org/1999/xhtml"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="api apidoc guide ml srv u v x xs xdmp">

  <xsl:import href="/view/page.xsl"/>

  <xdmp:import-module
      namespace="http://developer.marklogic.com/site/internal"
      href="/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api"
      href="/apidoc/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/view"
      href="/apidoc/view/view.xqm"/>

  <!-- Only used for a debugging function. -->
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/guide"
      href="/apidoc/setup/guide.xqm"/>

  <xsl:output indent="no"/>

  <!-- This may be empty. -->
  <xsl:variable name="VERSION" select="$params[@name eq 'version']/string()"/>

  <xsl:variable name="VERSION-FINAL"
                select="if ($VERSION) then $VERSION
                        else $api:DEFAULT-VERSION"/>

  <xsl:variable name="is-print-request"
                select="$params[@name eq 'print'] eq 'yes'"/>

  <!-- overrides variable declaration in imported code -->
  <xsl:variable name="currently-on-api-server" select="true()"/>

  <!--
      If current version is the default version,
      whether explicitly specified or not,
      then don't include the version prefix in links.
      See also $api:toc-uri in data-access.xqy
  -->
  <xsl:variable name="version-prefix"
                select="if ($VERSION-FINAL eq $api:DEFAULT-VERSION) then ''
                        else concat('/', $VERSION-FINAL)"/>

  <xsl:variable name="site-title"
                select="v:site-title($VERSION-FINAL)"/>

  <xsl:variable name="site-url-for-disqus"
                select="'http://docs.marklogic.com'"/>

  <xsl:variable name="template-dir"
                select="'/apidoc/config'"/>

  <xsl:variable name="show-alternative-functions"
                select="$params[@name eq 'show-alternatives']"/>

  <xsl:variable name="is-pjax-request"
                select="xdmp:get-request-header('X-PJAX') eq 'true'"/>

  <!-- Only set to true in development, not in production. -->
  <xsl:variable name="convert-at-render-time"
                select="doc-available('/apidoc/DEBUG.xml')
                        and doc('/apidoc/DEBUG.xml') eq 'yes'"/>

  <xsl:variable name="DOCS-PAGE" as="element(api:docs-page)"
                select="doc(api:internal-uri($VERSION-FINAL, '/'))/*"/>

  <xsl:variable name="AUTO-LINKS" as="element(auto-link)*"
                select="$DOCS-PAGE/auto-link"/>

  <xsl:variable name="OTHER-GUIDE-LISTINGS" as="element(api:user-guide)*">
    <xsl:variable name="content-uri-external" as="xs:string"
                  select="api:external-uri($content)"/>
    <xsl:copy-of select="$DOCS-PAGE/api:user-guide[
                         not(@href eq $content-uri-external) ]"/>
  </xsl:variable>

  <!--
      Redefines the function in ../../view/comments.xsl

      Don't include the version in the comments doc URI.
      Use just one conversation thread per function,
      regardless of server version.
  -->
  <xsl:function name="ml:uri-for-commenting-purposes" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <!-- Remove the version from the path -->
    <xsl:sequence select="u:strip-version-from-path(base-uri($node))"/>
  </xsl:function>

  <xsl:template match="/">
    <!-- empty sequence; evaluated only for side effect -->
    <xsl:if test="$set-version">
      <xsl:value-of select="$_set-cookie"/>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$is-print-request">
        <xsl:apply-templates mode="print-view" select="."/>
      </xsl:when>
      <xsl:when test="$is-pjax-request">
        <div>
          <!--PJAX!!-->
          <title>
            <xsl:apply-templates mode="page-title" select="*"/>
          </title>
          <xsl:copy-of select="v:toc-references($version-prefix, .)"/>
          <xsl:call-template name="page-content"/>
          <xsl:call-template name="apidoc-copyright"/>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ml:toc-state" name="toc-state">
    <xsl:copy-of select="v:toc-references($version-prefix, $content)"/>
  </xsl:template>

  <xsl:template match="ml:apidoc-copyright" name="apidoc-copyright">
    <xsl:copy-of select="v:apidoc-copyright()"/>
  </xsl:template>

  <xsl:template mode="print-view" match="*">
    <html>
      <head>
        <title>
          <xsl:apply-templates mode="page-specific-title" select="."/>
        </title>
        <link href="/css/v-1/apidoc_print.css" rel="stylesheet"
              type="text/css" media="screen, print"/>
      </head>
      <body>
        <xsl:apply-templates mode="page-content" select="."/>
        <xsl:call-template name="apidoc-copyright"/>
      </body>
    </html>
  </xsl:template>

  <!-- Links in content (including guide content) may need to be rewritten
       to include the current explicitly specified version -->
  <xsl:template mode="#default guide" match="x:a/@href[starts-with(.,'/')]">
    <xsl:attribute name="href" select="concat($version-prefix,.)"/>
  </xsl:template>

  <!-- Make search stick to the current API version -->
  <xsl:template match="x:input[@name eq $set-version-param-name]/@ml:value">
    <xsl:attribute name="value">
      <xsl:value-of select="$VERSION-FINAL"/>
    </xsl:attribute>
  </xsl:template>

  <!-- In the standalone version, display the "Documentation" badge -->
  <xsl:template match="x:header/x:h1/x:a/@ml:class"/>
  <xsl:template match="x:header/x:h1/x:a/@ml:class[$srv:viewing-standalone-api]" priority="1">
    <xsl:attribute name="class" select="'documentation'"/>
  </xsl:template>

  <!-- Add "apidoc" class to tables in content, so we can adjust the CSS without disrupting the rest of DMC -->
  <xsl:template mode="#default guide" match="x:table/@class"/>
  <xsl:template mode="#default guide" match="x:table">
    <xsl:copy>
      <xsl:attribute name="class" select="concat('api_generic_table ',@class)"/>
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ml:breadcrumbs">
    <xsl:apply-templates mode="breadcrumbs" select=".">
      <xsl:with-param name="site-name" select="'Docs'"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Placeholder for toc_filter.js init code. -->
  <xsl:template mode="breadcrumb-display"
                match="ml:breadcrumbs">
    <span id="breadcrumbDynamic"></span>
  </xsl:template>

  <xsl:template match="ml:versions">
    <!-- Server version widget. -->
    <xsl:apply-templates mode="version-list" select="."/>
  </xsl:template>

  <xsl:template match="ml:api-toc">
    <div id="apidoc_toc">
      <xsl:comment>TOC goes here</xsl:comment>
    </div>
  </xsl:template>

  <!-- Customizations of the "Server version" switcher code. -->
  <xsl:function name="ml:version-is-selected" as="xs:boolean">
    <xsl:param name="_version" as="xs:string"/>
    <xsl:copy-of select="$_version eq $VERSION-FINAL"/>
  </xsl:function>

  <xsl:template mode="page-title"
                match="api:docs-page">
    <xsl:value-of select="$site-title"/>
  </xsl:template>

  <xsl:template mode="page-title"
                match="message">
    <xsl:value-of select="$site-title"/>
    <xsl:text> &#x2014; </xsl:text>
    <xsl:value-of select="@id"/>
  </xsl:template>

  <!-- Override and extend base page.xsl page-specific-title mode. -->
  <xsl:template mode="page-specific-title"
                match="api:function-page[@mode eq $api:MODE-JAVASCRIPT]">
    <xsl:value-of select="api:function-name"/>
  </xsl:template>

  <xsl:template mode="page-specific-title"
                match="api:list-page | api:help-page">
    <xsl:value-of>
      <xsl:apply-templates mode="list-page-heading" select="."/>
    </xsl:value-of>
  </xsl:template>

  <xsl:template mode="api-page-heading"
                match="*
                       |api:function-page[api:function[1]/@lib eq $api:MODE-REST]">
    <xsl:apply-templates mode="page-specific-title" select="."/>
  </xsl:template>

  <xsl:template mode="api-page-heading"
                match="api:function-page">
    <xsl:variable
        name="name"
        select="api:function[1]/@fullname"/>
    <xsl:variable
        name="lib"
        select="api:function[1]/@lib"/>
    <xsl:variable
        name="is-javascript"
        select="@mode eq $api:MODE-JAVASCRIPT"/>
    <!-- Expect this to change. -->
    <xsl:variable name="delimiter"
                  select="if ($is-javascript) then '.'
                          else ':'"/>
    <!--
        usually the same as $lib,
        except "spell" vs. "spell-lib" and "json" vs. "json-lib"
    -->
    <xsl:variable name="prefix"
                  select="substring-before($name, $delimiter)"/>
    <xsl:variable name="local"
                  select="substring-after ($name, $delimiter)"/>

    <a href="{
             concat(
             $version-prefix,
             if ($is-javascript) then '/js/'
             else '/',
             $lib) }">
      <xsl:value-of select="$prefix"/>
    </a>
    <xsl:value-of select="$delimiter"/>
    <xsl:value-of select="$local"/>
  </xsl:template>

  <xsl:template name="did-you-mean-undo">
    <xsl:param name="q"/>
    <xsl:if test="$q">
      <xsl:text>Did you mean to search for the term </xsl:text>
      <!-- Force the search with p=1. -->
      <a href="{v:search-path($srv:search-page-url, $q, $VERSION)
               }&amp;p=1">
        <xsl:value-of select="$q"/>
      </a>
      <xsl:text>?</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="page-content"
                match="message">
    <xsl:if test="$q">
      <p class="didYouMean">
        <xsl:call-template name="did-you-mean-undo">
          <xsl:with-param name="q" select="$q"/>
        </xsl:call-template>
      </p>
    </xsl:if>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template mode="page-content"
                match="api:docs-page">
    <div>
      <xsl:apply-templates mode="pjax_enabled-class-att" select="."/>
      <h1>
        <xsl:apply-templates mode="page-title" select="."/>
      </h1>
      <xsl:apply-templates select="x:*"/>
    </div>
  </xsl:template>

  <!--
      Decorate guide links with pdf link.
      TODO make sure links are rewritten properly for version.
  -->
  <xsl:template match="x:a[@class eq 'guide-link']">
    <xsl:copy-of select="."/>
    <xsl:text> | </xsl:text>
    <xsl:copy-of select="v:pdf-anchor(., @href, false(), false())"/>
  </xsl:template>

  <!--
       This template matches entries with links or versions,
       plus guides that have information.
  -->
  <xsl:template mode="docs-list-item"
                match="apidoc:entry[@href]
                       | apidoc:guide[api:guide-info($content, @url-name)]">
    <xsl:variable name="href"
                  select="v:entry-href($version-prefix, ., $content)"/>
    <xsl:variable name="title"
                  select="v:entry-title(., $content)"/>
    <li>
      <a href="{$href}">
        <xsl:value-of select="$title"/>
      </a>
      <xsl:if test="self::apidoc:guide">
        <xsl:text> | </xsl:text>
        <xsl:copy-of select="v:pdf-anchor($title, $href, false(), false())"/>
      </xsl:if>
      <div>
        <xsl:copy-of select="v:entry-description($VERSION-FINAL, .)"/>
      </div>
    </li>
  </xsl:template>

  <xsl:template mode="print-friendly-link" match="*">
    <a href="?print=yes" target="_blank" class="printerFriendly">
      <img src="/apidoc/images/printerFriendly.png"/>
    </a>
  </xsl:template>

  <!-- Guide title -->
  <xsl:template mode="guide" match="/*/guide-title">
    <!--
        Add a PDF link at the top of each guide (and chapter), before the <h1>.
        If this is a chapter also provide a printer-friendly version.
    -->
    <xsl:copy-of select="v:pdf-anchor(
                         ., v:external-guide-uri($version-prefix, /),
                         exists(parent::chapter), true())"/>
    <!-- printer-friendly link on chapter pages -->
    <xsl:if test="parent::chapter">
      <xsl:apply-templates mode="print-friendly-link" select="."/>
    </xsl:if>
    <h1>
      <xsl:apply-templates mode="guide-heading-content" select="."/>
    </h1>
    <xsl:apply-templates mode="chapter-next-prev" select="../@previous, ../@next"/>
  </xsl:template>

  <xsl:template mode="page-content" match="api:help-page">
    <div>
      <xsl:apply-templates mode="pjax_enabled-class-att" select="."/>
      <xsl:apply-templates mode="print-friendly-link" select="."/>
      <h1>
        <xsl:apply-templates mode="list-page-heading" select="."/>
      </h1>
      <xsl:apply-templates select="api:content/node()"/>
    </div>
  </xsl:template>

  <xsl:template mode="page-content" match="api:list-page">
    <div>
      <xsl:apply-templates mode="pjax_enabled-class-att" select="."/>
      <xsl:apply-templates mode="print-friendly-link" select="."/>
      <h1>
        <xsl:apply-templates mode="list-page-heading" select="."/>
      </h1>
      <xsl:apply-templates select="api:intro/node()"/>
      <xsl:choose>
        <!-- Hack for showing module with no functions:
             Don't show the table if there are no functions.
        -->
        <xsl:when test="count(api:list-entry/api:name) eq 0"/>
        <xsl:otherwise>
          <div class="api_caption">
            <xsl:variable name="count" select="count(api:list-entry)"/>
            <xsl:value-of select="$count"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates mode="list-page-item-type" select="."/>
            <xsl:if test="$count gt 1">s</xsl:if>
          </div>
          <table class="api_table">
            <colgroup>
              <col class="col1"/>
              <col class="col2"/>
            </colgroup>
            <thead>
              <tr>
                <th>
                  <xsl:apply-templates mode="list-page-col-heading" select="."/>
                </th>
                <th>Description</th>
              </tr>
            </thead>
            <tbody>
              <xsl:apply-templates mode="list-page-entry" select="api:list-entry"/>
            </tbody>
          </table>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <xsl:template mode="pjax_enabled-class-att" match="*">
    <xsl:attribute name="class">pjax_enabled</xsl:attribute>
  </xsl:template>

  <!-- These api:title elements may contain links which need to be rewritten. -->
  <xsl:template mode="list-page-heading" match="api:list-page | api:help-page">
    <xsl:apply-templates select="api:title/node()"/>
  </xsl:template>

  <!-- If a name starts with a "/", that means this is a list of REST resources -->
  <xsl:template mode="list-page-col-heading"
                match="api:list-page[
                       api:list-entry[1]/api:name[
                       starts-with(.,'/')]]">Resource URI</xsl:template>
  <xsl:template mode="list-page-col-heading"
                match="api:list-page">Function name</xsl:template>

  <!-- If a name starts with a "/", that means this is a list of REST resources -->
  <xsl:template mode="list-page-item-type"
                match="api:list-page[
                       api:list-entry[1]/api:name[
                       starts-with(.,'/')]]">resource</xsl:template>
  <xsl:template mode="list-page-item-type"
                match="api:list-page">function</xsl:template>

  <xsl:template mode="list-page-entry" match="api:list-entry">
    <tr>
      <td>
        <xsl:if test="api:name/@indent">
          <xsl:attribute name="class" select="'indented_function'"/>
        </xsl:if>
        <a href="{$version-prefix}{@href}">
          <xsl:value-of select="api:name"/>
        </a>
      </td>
      <td>
        <xsl:apply-templates select="api:description/node()"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template mode="function-links"
                match="api:function-page"/>

  <xsl:template mode="function-links"
                match="api:function-page[api:function-link]">
    <div class="api-function-links">
      <xsl:for-each select="api:function-link">
        <a class="api-function-link"
           href="{ $version-prefix }/{ @fullname/string() }">
          <xsl:value-of select="if (@mode = $api:MODE-XPATH) then 'XQuery'
                                else 'JavaScript'"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@fullname/string()"/>
        </a>
        <xsl:text> </xsl:text>
      </xsl:for-each>
    </div>
  </xsl:template>

  <xsl:template mode="page-content"
                match="api:function-page">
    <xsl:if test="$show-alternative-functions or $q">
      <xsl:variable name="other-matches"
                    select="ml:get-matching-functions(
                            api:function[1]/@name, $VERSION-FINAL)
                            /api:function-page except ."/>
      <p class="didYouMean">
        <xsl:if test="$other-matches">
          <xsl:text>Did you mean </xsl:text>
          <xsl:for-each select="$other-matches">
            <xsl:variable name="fullname" select="api:function[1]/@fullname"/>
            <a href="{$version-prefix}/{$fullname}">
              <xsl:value-of select="$fullname"/>
            </a>
            <xsl:if test="position() ne last()"> or </xsl:if>
          </xsl:for-each>
          <xsl:text>? </xsl:text>
        </xsl:if>
        <xsl:call-template name="did-you-mean-undo">
          <xsl:with-param name="q" select="$q"/>
        </xsl:call-template>
      </p>
    </xsl:if>
    <div>
      <xsl:apply-templates mode="pjax_enabled-class-att" select="."/>
      <xsl:apply-templates mode="print-friendly-link" select="."/>
      <xsl:apply-templates mode="function-links" select="."/>
      <h1>
        <xsl:apply-templates mode="api-page-heading" select="."/>
      </h1>
      <xsl:apply-templates select="api:function"/>
    </div>
  </xsl:template>

  <xsl:template match="api:function">
    <xsl:apply-templates mode="function-signature" select="."/>
    <xsl:apply-templates select="(api:summary, api:params)[normalize-space(.)]"/>
    <xsl:apply-templates select="api:headers[api:header/@type = 'request']"/>
    <xsl:apply-templates select="api:headers[api:header/@type = 'response']">
      <xsl:with-param name="response-headers" select="true()" tunnel="yes"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="(api:response, api:privilege,
                                 api:usage, api:see-also-list, api:example)
                                 [normalize-space(.)]"/>
    <xsl:if test="position() ne last()"> <!-- if it's *:polygon() -->
      <br/>
      <br/>
      <hr/>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="function-signature"
                match="api:function[@lib eq $api:MODE-REST]"/>

  <xsl:template mode="function-signature" match="api:function">
    <!--
        Workaround for "not a bug" #13495
        (automatic setting of xml:space="preserve" on <pre>
        thanks to application of the XHTML schema to the stylesheet)
    -->
    <xsl:element name="pre">
      <xsl:value-of select="@fullname"/>
      <xsl:text>(</xsl:text>
      <xsl:if test="api:params/api:param">
        <xsl:text>&#xA;</xsl:text>
      </xsl:if>
      <xsl:apply-templates mode="syntax" select="api:params/api:param"/>
      <xsl:text>) as </xsl:text>
      <xsl:if test="api:return">
        <!-- Guard against bad content. -->
        <xsl:variable name="mode" as="xs:string" select="@mode"/>
        <xsl:value-of select="api:type(
                              $mode,
                              (api:return[not(@class)
                              or xs:NMTOKENS(@class) = $mode])[1])"/>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <xsl:template mode="syntax" match="api:param">
    <xsl:text>   </xsl:text>
    <xsl:if test="@optional eq 'true'">[</xsl:if>
    <xsl:variable name="anchor">
      <xsl:apply-templates mode="param-anchor-id" select="."/>
    </xsl:variable>
    <a href="#{$anchor}" class="paramLink">
      <xsl:text>$</xsl:text>
      <xsl:value-of select="@name"/>
    </a>
    <xsl:text> as </xsl:text>
    <xsl:value-of select="api:type(../../@mode, @type)"/>
    <xsl:if test="@optional eq 'true'">]</xsl:if>
    <xsl:if test="position() ne last()">,</xsl:if>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template mode="param-anchor-id" match="api:param | api:header">
    <xsl:value-of select="@name"/>
  </xsl:template>

  <!--
      For the *:polygon functions,
      which have more than one function element on the same page.
  -->
  <xsl:template
      mode="param-anchor-id"
      match="/api:function-page/api:function[2]/api:params/api:param">
    <xsl:next-match/>
    <xsl:text>2</xsl:text>
  </xsl:template>

  <xsl:template match="api:summary">
    <h3>Summary</h3>
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="api:response">
    <h3>Response</h3>
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="api:params | api:headers">
    <xsl:param name="response-headers" tunnel="yes"/>
    <table class="parameters">
      <colgroup>
        <col class="col1"/>
        <col class="col2"/>
      </colgroup>
      <thead>
        <tr>
          <th scope="colgroup" colspan="2">
            <xsl:apply-templates mode="parameters-table-heading" select="."/>
          </th>
        </tr>
      </thead>
      <tbody>
        <xsl:apply-templates
            select="api:param
                    | api:header[
                    if ($response-headers) then (@type eq 'response')
                    else (@type eq 'request')]"/>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template mode="parameters-table-heading"
                match="api:function[@lib eq $api:MODE-REST]/api:headers">
    <xsl:param name="response-headers" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$response-headers">Response</xsl:when>
      <xsl:otherwise>Request</xsl:otherwise>
    </xsl:choose>
    <xsl:text> Headers</xsl:text>
  </xsl:template>
  <xsl:template mode="parameters-table-heading"
                match="api:function[@lib eq $api:MODE-REST]/api:params">URL Parameters</xsl:template>
  <xsl:template mode="parameters-table-heading"
                match=" api:params">Parameters</xsl:template>

  <xsl:template match="api:param | api:header">
    <tr>
      <td>
        <xsl:variable name="anchor">
          <xsl:apply-templates mode="param-anchor-id" select="."/>
        </xsl:variable>
        <a name="{$anchor}"/>
        <xsl:if test="not(../../@lib eq $api:MODE-REST)">
          <xsl:text>$</xsl:text>
        </xsl:if>
        <xsl:value-of select="@name"/>
      </td>
      <td>
        <xsl:apply-templates/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="api:privilege">
    <h3>Required Privileges</h3>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="api:see-also">
    <li><xsl:apply-templates/></li>
  </xsl:template>
  <xsl:template match="api:see-also-list">
    <h3>See Also</h3>
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="api:usage">
    <xsl:if test="empty(preceding-sibling::api:usage)">
      <h3>Usage Notes</h3>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="api:schema-info">
    <p>
      <xsl:apply-templates mode="schema-info-intro"
                           select="."/>
    </p>
    <dl>
      <xsl:apply-templates select="api:element"/>
    </dl>
  </xsl:template>

  <xsl:template mode="schema-info-intro"
                match="api:schema-info[not(@REST-doc)]
                       [not(@print-intro/string() eq 'false')]"
                >The structure of the data returned is as
  follows:</xsl:template>
  <xsl:template mode="schema-info-intro"
                match="api:schema-info[@REST-doc]
                       [not(@print-intro/string() eq 'false')]"
                >The structure of the output returned from
  this REST API is as follows:</xsl:template>

  <xsl:template mode="schema-info-intro"
                match="api:schema-info[@REST-doc]
                       [(@print-intro/string() eq 'false')]"
                ></xsl:template>

  <xsl:template match="api:element">
    <dt>
      <code>
        <xsl:value-of select="api:element-name"/>
      </code>
    </dt>
    <dd>
      <p>
        <xsl:apply-templates select="api:element-description/node()"/>
      </p>
      <xsl:if test="api:element">
        <p>This is a complex element with the following element children:</p>
        <dl>
          <xsl:apply-templates select="api:element"/>
        </dl>
      </xsl:if>
    </dd>
  </xsl:template>

  <xsl:template match="api:example">
    <h3>Example</h3>
    <div class="example">
      <xsl:copy-of select="((pre|pre/a)/@id)[1]"/>
      <xsl:apply-templates/>
    </div>
    <!-- Use this if we re-enable syntax highlighting
         <xsl:element name="pre">
         <code>
         <div class="example">
         <!- - Move the <pre> ID to its parent, so it doesn't get stripped
         off by the syntax-highlighting code (thereby breaking any links to it). - ->
         <xsl:copy-of select="((pre|pre/a)/@id)[1]"/>
         <xsl:apply-templates/>
         </div>
         </code>
         </xsl:element>
    -->
  </xsl:template>

  <!-- Strip the @id off the example pre (because we've reassigned it) -->
  <xsl:template match="api:example/pre  /@id
                       | api:example/pre/a/@id"/>


  <!-- Disable the body class stuff -->
  <xsl:template mode="body-class
                      body-class-extra" match="*"/>

  <!-- Don't ever add any special CSS classes -->
  <xsl:template mode="body-class-extra" match="*"/>

  <!-- guide templates -->
  <!-- Disable comments on User Guide pages -->
  <xsl:template mode="comment-section" match="/guide | /chapter"/>

  <xsl:template mode="page-content" match="/guide | /chapter">
    <div class="userguide pjax_enabled">
      <xsl:choose>
        <!-- The normal case: the guide is already converted (at "build time", i.e. the setup phase). -->
        <xsl:when test="not($convert-at-render-time)">
          <xsl:apply-templates mode="guide"/>
        </xsl:when>
        <!-- For development purposes only. Normally, assume that the guide is already converted (in the setup phase). -->
        <xsl:otherwise>
          <p style="position:fixed; color: red"><br/><br/>WARNING: This was converted directly from the raw docs database for convenience in development.
             Set the $convert-at-render-time flag to false in production (and this warning will go away).</p>
          <!-- Convert and render the guide directly, for development.  -->
          <xsl:apply-templates
              mode="guide"
              select="guide:convert-uri(
                      $VERSION-FINAL,
                      base-uri(current()))/*/node()"/>
        </xsl:otherwise>
      </xsl:choose>
    </div>
    <xsl:apply-templates mode="chapter-next-prev" select="@previous,@next"/>
    <!-- "Next" link on Table of Contents (guide) page -->
    <xsl:apply-templates mode="guide-next" select="@next"/>
  </xsl:template>

  <!-- Don't link to the guide root when we're already on it -->
  <xsl:template mode="guide-heading-content" match="/guide/guide-title">
    <xsl:apply-templates mode="guide-title" select="."/>
  </xsl:template>

  <!-- Make the guide heading a link when we're on a chapter page -->
  <xsl:template mode="guide-heading-content" match="/chapter/guide-title">
    <a href="{ v:external-guide-uri($version-prefix, /) }">
      <xsl:apply-templates mode="guide-title" select="."/>
    </a>
    <span class="chapterNumber"> &#8212; Chapter&#160;<xsl:value-of select="../@number"/></span>
  </xsl:template>

  <!-- Wrap <sup> around ® character -->
  <xsl:template mode="guide-title" match="guide-title">
    <xsl:analyze-string select="." regex="®">
      <xsl:matching-substring>
        <sup>
          <xsl:value-of select="."/>
        </sup>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>


  <!--
      Only show the next/prev links on chapter pages,
      and just "Next" on the guide page.
  -->
  <xsl:template mode="chapter-next-prev
                      guide-next" match="@*"/>
  <xsl:template mode="guide-next" match="guide/@next">
    <xsl:call-template name="guide-next"/>
  </xsl:template>
  <xsl:template mode="chapter-next-prev" name="guide-next"
                match="chapter/@next | chapter/@previous">
    <div class="{local-name(.)}Chapter">
      <a href="{api:external-uri-with-prefix($version-prefix, .)}"
         accesskey="{if (local-name(.) eq 'previous') then 'p' else 'n'}">
        <xsl:apply-templates mode="next-or-prev" select="."/>
      </a>
    </div>
  </xsl:template>

  <xsl:template mode="next-or-prev" match="guide/@next"                 >Next&#160;»</xsl:template>
  <xsl:template mode="next-or-prev" match="@next"                       >Next&#160;chapter&#160;»</xsl:template>
  <xsl:template mode="next-or-prev" match="@previous"                   >«&#160;Previous&#160;chapter</xsl:template>
  <xsl:template mode="next-or-prev" match="@previous[../@number eq '1']">«&#160;Table&#160;of&#160;contents</xsl:template>

  <xsl:template mode="guide" match="guide/info">
    <table class="guide_info api_generic_table">
      <tr>
        <th>Server version</th>
        <th>Date</th>
        <th>Revision</th>
      </tr>
      <tr>
        <td>
          <xsl:value-of select="version"/>
        </td>
        <td>
          <xsl:value-of select="date"/>
        </td>
        <td>
          <xsl:value-of select="revision"/>
        </td>
      </tr>
    </table>
  </xsl:template>

  <xsl:template mode="guide" match="guide/chapter-list">
    <p>This guide includes the following chapters:</p>
    <ol>
      <xsl:apply-templates mode="guide" select="chapter"/>
    </ol>
  </xsl:template>

  <xsl:template mode="guide" match="chapter">
    <li>
      <a href="{api:external-uri-with-prefix($version-prefix, @href)}">
        <xsl:apply-templates mode="guide"/>
      </a>
    </li>
  </xsl:template>

  <!-- Automatically convert italicized guide references to links, but not the
       ones that are immediately preceded by "in the", in which case we
       assume a more specific section link was already provided.
  -->
  <xsl:template mode="guide" match="x:em[v:config-for-title(
                                    ., $AUTO-LINKS, $OTHER-GUIDE-LISTINGS) ][
          not(preceding-sibling::node()[1][self::text()][
          normalize-space(.) eq 'in the'])]">
    <a href="{$version-prefix}{
             v:config-for-title(., $AUTO-LINKS, $OTHER-GUIDE-LISTINGS)/@href}">
      <xsl:next-match/>
    </a>
  </xsl:template>

  <!-- Boilerplate copying code -->
  <xsl:template mode="guide" match="node()">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template mode="guide" match="*">
    <xsl:copy>
      <xsl:copy-of select="v:guide-attributes(.)"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
