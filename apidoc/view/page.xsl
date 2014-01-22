<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:u="http://marklogic.com/rundmc/util"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  xmlns:srv="http://marklogic.com/rundmc/server-urls"
  xmlns:x="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="x xs ml xdmp api u srv">

  <xsl:import href="../../view/page.xsl"/>
  <xsl:import href="xquery-imports.xsl"/>

  <xsl:import href="../setup/REST-common.xsl"/>

  <xsl:include href="guide.xsl"/>
  <xsl:include href="uri-translation.xsl"/>

  <xsl:variable name="is-print-request" select="$params[@name eq 'print'] eq 'yes'"/>

  <!-- overrides variable declaration in imported code -->
  <xsl:variable name="currently-on-api-server" select="true()"/>

  <!-- Include the version prefix (e.g., "/4.2") when explicitly specified; otherwise don't -->
  <!--
  <xsl:variable name="version-prefix" select="if (not($api:version-specified)) then '' else concat('/',$api:version-specified)"/>
  -->

  <!-- Alternative behavior: if current version is the default version (whether explicitly specified or not),
       then don't include the version prefix in links; see also $api:toc-url in data-access.xqy -->
  <xsl:variable name="version-prefix" select="if ($api:version eq $api:default-version) then '' else concat('/',$api:version-specified)"/>

  <xsl:function name="ml:external-uri-with-prefix" as="xs:string">
    <xsl:param name="internal-uri" as="xs:string"/>
    <xsl:sequence select="concat($version-prefix, ml:external-uri-for-string($internal-uri))"/>
  </xsl:function>

  <xsl:variable name="doc-list-config" select="u:get-doc('/apidoc/config/document-list.xml')/docs"/>

  <!--
  <xsl:variable name="site-title" select="concat('MarkLogic Server ',$api:version,' Product Documentation')"/>
                                                                     -->
  <xsl:variable name="site-title" select="
    if ($api:version eq '5.0') 
    then 'MarkLogic 5 Product Documentation'
    else if ($api:version eq '6.0') 
         then 'MarkLogic 6 Product Documentation'
         else if ($api:version eq '7.0')
              then 'MarkLogic 7 Product Documentation'
              else concat('MarkLogic Server ',$api:version,
                          ' Product Documentation')"/>

  <xsl:variable name="site-url-for-disqus" select="'http://docs.marklogic.com'"/>

  <xsl:variable name="template-dir" select="'/apidoc/config'"/>

  <xsl:variable name="show-alternative-functions" select="$params[@name eq 'show-alternatives']"/>

  <xsl:variable name="is-pjax-request" select="xdmp:get-request-header('X-PJAX') eq 'true'"/>

  <xsl:template match="/">
    <xsl:if test="$set-version">
      <xsl:value-of select="$_set-cookie"/> <!-- empty sequence; evaluated only for side effect -->
    </xsl:if>
    <!--
    <xsl:value-of select="$content/.."/>
    <xsl:value-of select="substring-after($external-uri,$external-uri)"/>
    -->
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
          <script type="text/javascript">
            <xsl:comment>

              <xsl:call-template name="reset-global-toc-vars"/>

            </xsl:comment>
          </script>
          <xsl:call-template name="page-content"/>
          <xsl:call-template name="comment-section"/>
          <xsl:call-template name="apidoc-copyright"/>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

          <xsl:template match="ml:apidoc-copyright" name="apidoc-copyright">
            <div id="copyright">Copyright &#169; 2014 MarkLogic Corporation. All rights reserved. | Powered by
              <!-- Absolute links so they work uniformly on standalone docs app -->
              <a href="http://developer.marklogic.com/products">MarkLogic Server <ml:server-version/></a> and <a href="http://developer.marklogic.com/code/rundmc">rundmc</a>.
            </div>
          </xsl:template>

  <xsl:template mode="print-view" match="*">
    <html>
      <head>
        <title>
          <xsl:apply-templates mode="page-specific-title" select="."/>
        </title>
        <link href="/css/v-1/apidoc_print.css" rel="stylesheet" type="text/css" media="screen, print"/>
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
      <xsl:value-of select="$api:version"/>
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
    <xsl:apply-templates mode="breadcrumbs" select="."/>
    <!-- Always append the "Server version" switcher -->
    <xsl:apply-templates mode="version-list" select="."/>
  </xsl:template>

          <!-- TODO: Make the breadcrumbs more useful (and make sure PJAX is supported) -->
          <xsl:template mode="breadcrumb-display" match="ml:breadcrumbs"> > Documentation</xsl:template>

  <xsl:template match="ml:api-toc">
    <div id="apidoc_toc">
      <script type="text/javascript">
        <xsl:comment>

        <xsl:call-template name="reset-global-toc-vars"/>

        $('#apidoc_toc').load('<xsl:value-of select="$api:toc-url"/>');

      </xsl:comment>
      </script>
    </div>
  </xsl:template>

          <!-- Customizations of the "Server version" switcher code (slightly different than the search results page) -->

          <xsl:template mode="version-list-item-selected-or-not" match="version[@number eq $api:version]">
            <xsl:call-template name="show-selected-version"/>
          </xsl:template>
          <xsl:template mode="version-list-item-selected-or-not" match="version">
            <xsl:call-template name="show-unselected-version"/>
          </xsl:template>

          <xsl:template mode="version-list-item-href" match="version">
            <xsl:variable name="version" select="if (@number eq $api:default-version) then '' else @number"/>
            <xsl:sequence select="concat('/', $version, '?', $set-version-param-name, '=', @number)"/>
          </xsl:template>


          <xsl:template name="reset-global-toc-vars">
            <!-- Used to determine which TOC section to load when switching to the Categories tab -->
            var functionPageBucketId = "<xsl:apply-templates mode="function-bucket-id" select="$content/api:function-page/api:function[1]/@bucket
                                                                                             | $content/api:list-page/@category-bucket"/>";
            var tocSectionLinkSelector = "<xsl:apply-templates mode="toc-section-link-selector" select="$content/*"/>";

            var isUserGuide = <xsl:apply-templates mode="is-user-guide" select="$content/*"/>;
          </xsl:template>

                  <xsl:template mode="is-user-guide" match="guide | chapter">true</xsl:template>
                  <xsl:template mode="is-user-guide" match="*"              >false</xsl:template>


          <!-- ID for function buckets is the bucket display name minus spaces; see tocByCategory.xsl -->
          <xsl:template mode="function-bucket-id" match="@*">
            <xsl:value-of select="translate(.,' ','')"/>
          </xsl:template>


          <xsl:template mode="toc-section-link-selector" match="api:function-page">
            <xsl:text>.scrollable_section a[href='</xsl:text>
            <xsl:value-of select="$version-prefix"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="api:function[1]/@lib"/>
            <xsl:text>']</xsl:text>
          </xsl:template>

          <xsl:template mode="toc-section-link-selector" match="guide | chapter">
            <xsl:text>.scrollable_section a[href='</xsl:text>
            <xsl:value-of select="ml:external-uri-with-prefix(@guide-uri)"/>
            <xsl:text>']</xsl:text>
          </xsl:template>

          <xsl:template mode="toc-section-link-selector" match="api:list-page | api:help-page">
            <xsl:text>#</xsl:text>
            <xsl:value-of select="@container-toc-section-id"/>
            <xsl:text> >:first-child</xsl:text>
          </xsl:template>

          <!-- On the main docs page, just let the first tab be selected by default. -->
          <xsl:template mode="toc-section-link-selector" match="api:docs-page"/>


  <xsl:template mode="page-title" match="api:docs-page">
    <xsl:value-of select="$site-title"/>
  </xsl:template>

  <xsl:template mode="page-specific-title" match="api:list-page | api:help-page">
    <xsl:value-of>
      <xsl:apply-templates mode="list-page-heading" select="."/>
    </xsl:value-of>
  </xsl:template>


  <!-- currently not used -->
  <xsl:template match="ml:page-heading">
    <h1>
      <xsl:apply-templates mode="api-page-heading" select="$content/*"/>
    </h1>
  </xsl:template>

          <xsl:template mode="api-page-heading" match="* | api:function-page[api:function[1]/@lib eq 'REST']">
            <xsl:apply-templates mode="page-specific-title" select="."/>
          </xsl:template>

          <xsl:template mode="api-page-heading" match="api:function-page">
            <xsl:variable name="name" select="api:function[1]/@fullname"/>
            <xsl:variable name="lib"  select="api:function[1]/@lib"/>

            <!-- usually the same as $lib, excepting "spell" vs. "spell-lib" and "json" vs. "json-lib" -->
            <xsl:variable name="prefix" select="substring-before($name,':')"/>
            <xsl:variable name="local"  select="substring-after ($name,':')"/>

                                               <!-- Is this class necessary anymore? -->
            <a href="{$version-prefix}/{$lib}" class="function_prefix">
              <xsl:value-of select="$prefix"/>
            </a>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="$local"/>
          </xsl:template>


  <xsl:template mode="page-content" match="api:docs-page">
    <div>
      <xsl:apply-templates mode="pjax_enabled-class-att" select="."/>
      <h1>
        <xsl:apply-templates mode="page-title" select="."/>
      </h1>
      <xsl:apply-templates mode="docs-page" select="$doc-list-config/*"/>
    </div>
  </xsl:template>

          <xsl:template mode="docs-page" match="group[@min-version gt $api:version]" priority="3"/>

          <xsl:template mode="docs-page" match="group" priority="2">
            <h3><xsl:value-of select="@name"/></h3>
            <xsl:next-match/>
          </xsl:template>

          <xsl:template mode="docs-page" match="group | unnamed-group" priority="1">
            <ul class="doclist">
              <!-- not using this anymore
              <xsl:apply-templates mode="hard-coded-doc-list-items" select="."/>
              -->
              <xsl:apply-templates mode="docs-list-item" select="*"/>
            </ul>
          </xsl:template>

                  <!-- disabled
                  <xsl:template mode="hard-coded-doc-list-items" match="group"/>
                  <xsl:template mode="hard-coded-doc-list-items" match="unnamed-group">
                    <li>
                      <a href="javascript:$('#toc_tabs').tabs('select',0);">MarkLogic XQuery and XSLT Function Reference</a>
                      <div>You're there already! Navigate to individual built-in and XQuery library function docs using the menu to the left.</div>
                    </li>
                    <li>
                      <a href="javascript:$('#toc_tabs').tabs('select',3);">REST API Reference</a>
                      <div>This API reference documents the REST resources available on port 8002. Navigate to individual REST resource docs using the <a href="javascript:$('#toc_tabs').tabs('select',3);">menu to the left</a>.</div>
                    </li>
                  </xsl:template>
                  -->


                  <xsl:template mode="docs-list-item" match="*"/>

                  <xsl:template mode="docs-list-item" match="entry[@min-version gt $api:version]" priority="1"/>

                  <xsl:template mode="docs-list-item" match="entry[@href or url/@version = $api:version]
                                                           | guide[api:guide-info(@url-name)]">
                    <xsl:variable name="href">
                      <xsl:apply-templates mode="entry-href" select="."/>
                    </xsl:variable>
                    <xsl:variable name="title">
                      <xsl:apply-templates mode="entry-title" select="."/>
                    </xsl:variable>
                    <li>
                      <a href="{$href}">
                        <xsl:value-of select="$title"/>
                      </a>
                      <xsl:if test="self::guide">
                        <xsl:text> | </xsl:text>
                        <a href="{$href}.pdf">
                          <img src="/images/i_pdf.png" alt="{$title} (PDF)" width="25" height="26"/>
                        </a>
                      </xsl:if>
                      <div>
                        <xsl:apply-templates mode="entry-description" select="."/>
                      </div>
                    </li>
                  </xsl:template>

                          <!-- The following group of rules is used by the list page too -->

                          <!-- Strip out phrases that don't apply to older server versions -->
                          <xsl:template mode="entry-description" match="added-in[$api:version lt @version]"/>

                          <xsl:template mode="entry-description" match="version-suffix">
                            <xsl:choose>
                              <xsl:when test="$api:version eq '5.0'">5</xsl:when>
                              <xsl:when test="$api:version eq '6.0'">6</xsl:when>
                              <xsl:otherwise>
                                <xsl:text>Server </xsl:text>
                                <xsl:value-of select="$api:version"/>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:template>


                          <xsl:template mode="entry-href" match="guide">
                            <xsl:value-of select="$version-prefix"/>
                            <xsl:value-of select="api:guide-info(@url-name)/@href"/>
                          </xsl:template>

                                  <xsl:function name="api:guide-info" as="element()?">
                                    <xsl:param name="url-name" as="attribute()"/>
                                    <xsl:sequence select="$content/*/api:user-guide[@href/ends-with(.,$url-name/concat('/',.))]"/>
                                  </xsl:function>

                          <!-- entry/url/@href must include the whole path (version prefix not added) -->
                          <xsl:template mode="entry-href" match="entry[url]" priority="1">
                            <xsl:value-of select="url[@version eq $api:version]/@href"/>
                          </xsl:template>

                          <!-- entry/@href gets the version prefix added -->
                          <xsl:template mode="entry-href" match="entry[@href]">
                            <xsl:value-of select="$version-prefix"/>
                            <xsl:value-of select="@href"/>
                          </xsl:template>


                          <xsl:template mode="entry-title" match="guide">
                            <xsl:value-of select="api:guide-info(@url-name)/@display"/>
                          </xsl:template>

                          <xsl:template mode="entry-title" match="entry">
                            <xsl:value-of select="@title"/>
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

  <xsl:template mode="page-content" match="api:list-page"><!-- | api:docs-page">-->
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

          <xsl:template mode="list-page-heading" match="api:list-page | api:help-page">
            <xsl:apply-templates select="api:title/node()"/>
          </xsl:template>


          <!-- If a name starts with a "/", that means this is a list of REST resources -->
          <xsl:template mode="list-page-col-heading" match="api:list-page[api:list-entry[1]/api:name[starts-with(.,'/')]]">Resource URI</xsl:template>
          <xsl:template mode="list-page-col-heading" match="api:list-page"                                                >Function name</xsl:template>

          <!-- If a name starts with a "/", that means this is a list of REST resources -->
          <xsl:template mode="list-page-item-type" match="api:list-page[api:list-entry[1]/api:name[starts-with(.,'/')]]">resource</xsl:template>
          <xsl:template mode="list-page-item-type" match="api:list-page"                                                >function</xsl:template>


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


  <xsl:template mode="page-content" match="api:function-page">
    <xsl:if test="$show-alternative-functions or $q">
      <xsl:variable name="other-matches" select="ml:get-matching-functions(api:function[1]/@name, $api:version)/api:function-page except ."/>
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
        <xsl:if test="$q">
          <xsl:text>Did you mean to search for the term </xsl:text>
          <a href="{$srv:search-page-url}?q={$q}&amp;p=1"> <!-- p=1 effectively forces the search -->
            <xsl:value-of select="$q"/>
          </a>
          <xsl:text>?</xsl:text>
        </xsl:if>
      </p>
    </xsl:if>
    <div>
      <xsl:apply-templates mode="pjax_enabled-class-att" select="."/>
      <xsl:apply-templates mode="print-friendly-link" select="."/>
      <h1>
        <xsl:apply-templates mode="api-page-heading" select="."/>
      </h1>
      <xsl:apply-templates select="api:function"/>
    </div>
  </xsl:template>

          <xsl:template mode="print-friendly-link" match="*">
            <a href="?print=yes" target="_blank" class="printerFriendly">
              <img src="/apidoc/images/printerFriendly.png"/>
            </a>
          </xsl:template>


          <xsl:template match="api:function">
            <xsl:apply-templates mode="function-signature" select="."/>
            <xsl:apply-templates select="(api:summary, api:params)[normalize-space(.)]"/>
            <xsl:apply-templates select="api:headers[api:header/@type = 'request']"/>
            <xsl:apply-templates select="api:headers[api:header/@type = 'response']">
              <xsl:with-param name="response-headers" select="true()" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="(api:response, api:privilege, api:usage, api:example)[normalize-space(.)]"/>
            <xsl:if test="position() ne last()"> <!-- if it's *:polygon() -->
              <br/>
              <br/>
              <hr/>
            </xsl:if>
          </xsl:template>

                  <xsl:template mode="function-signature" match="api:function[@lib eq 'REST']"/>
                  <xsl:template mode="function-signature" match="api:function">
                    <!-- Workaround for "not a bug" #13495 (automatic setting of xml:space="preserve" on <pre> thanks to application of the XHTML schema to the stylesheet) -->
                    <xsl:element name="pre">
                      <xsl:value-of select="@fullname"/>
                      <xsl:text>(</xsl:text>
                      <xsl:if test="api:params/api:param">
                        <xsl:text>&#xA;</xsl:text>
                      </xsl:if>
                      <xsl:apply-templates mode="syntax" select="api:params/api:param"/>
                      <xsl:text>) as </xsl:text>
                      <xsl:value-of select="normalize-space(api:return)"/>
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
                            <xsl:value-of select="@type"/>
                            <xsl:if test="@optional eq 'true'">]</xsl:if>
                            <xsl:if test="position() ne last()">,</xsl:if>
                            <xsl:text>&#xA;</xsl:text>
                          </xsl:template>

                                  <xsl:template mode="param-anchor-id" match="api:param | api:header">
                                    <xsl:value-of select="@name"/>
                                  </xsl:template>
                                  <!-- For the *:polygon functions (having more than one function element on the same page) -->
                                  <xsl:template mode="param-anchor-id" match="/api:function-page/api:function[2]/api:params/api:param">
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
                        <xsl:apply-templates select="api:param | api:header[if ($response-headers) then (@type eq 'response')
                                                                                                   else (@type eq 'request')]"/>
                      </tbody>
                    </table>
                  </xsl:template>

                          <xsl:template mode="parameters-table-heading" match="api:function[@lib eq 'REST']/api:headers">
                            <xsl:param name="response-headers" tunnel="yes"/>
                            <xsl:choose>
                              <xsl:when test="$response-headers">Response</xsl:when>
                              <xsl:otherwise>Request</xsl:otherwise>
                            </xsl:choose>
                            <xsl:text> Headers</xsl:text>
                          </xsl:template>
                          <xsl:template mode="parameters-table-heading" match="api:function[@lib eq 'REST']/api:params">URL Parameters</xsl:template>
                          <xsl:template mode="parameters-table-heading" match="                             api:params">Parameters</xsl:template>

                          <xsl:template match="api:param | api:header">
                            <tr>
                              <td>
                                <xsl:variable name="anchor">
                                  <xsl:apply-templates mode="param-anchor-id" select="."/>
                                </xsl:variable>
                                <a name="{$anchor}"/>
                                <xsl:if test="not(../../@lib eq 'REST')">
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

                  <xsl:template match="api:usage">
                    <h3>Usage Notes</h3>
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



  <!-- Don't include the version in the comments doc URI; use just one conversation thread per function, regardless of server version -->
  <!-- Redefines the function in ../../view/comments.xsl -->
  <xsl:function name="ml:uri-for-commenting-purposes" as="xs:string">
    <xsl:param name="node"/>
    <!-- Remove the version from the path -->
    <xsl:sequence select="u:strip-version-from-path(base-uri($node))"/>
  </xsl:function>

  <!-- Don't ever add any special CSS classes -->
  <xsl:template mode="body-class-extra" match="*"/>

</xsl:stylesheet>
