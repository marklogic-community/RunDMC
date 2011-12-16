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

  <xsl:include href="guide.xsl"/>

  <!-- overrides variable declaration in imported code -->
  <xsl:variable name="currently-on-api-server" select="true()"/>

  <!-- Include the version prefix (e.g., "/4.2") when explicitly specified; otherwise don't -->
  <!--
  <xsl:variable name="version-prefix" select="if (not($api:version-specified)) then '' else concat('/',$api:version-specified)"/>
  -->

  <!-- Alternative behavior: if current version is the default version (whether explicitly specified or not),
       then don't include the version prefix in links; see also $api:toc-url in data-access.xqy -->
  <xsl:variable name="version-prefix" select="if ($api:version eq $api:default-version) then '' else concat('/',$api:version-specified)"/>

  <xsl:variable name="doc-list-config" select="u:get-doc('/apidoc/config/document-list.xml')/docs"/>

  <xsl:variable name="site-title" select="if ($api:version eq '5.0') then 'MarkLogic 5 Product Documentation'
                                                                     else concat('MarkLogic Server ',$api:version,' Product Documentation')"/>

  <xsl:variable name="site-url-for-disqus" select="'http://api.marklogic.com'"/>

  <xsl:variable name="template-dir" select="'/apidoc/config'"/>

  <xsl:variable name="show-alternative-functions" select="$params[@name eq 'show-alternatives']"/>

  <xsl:variable name="is-pjax-request" select="$params[@name eq '_pjax'] eq 'true'"/>

  <xsl:template match="/">
    <!--
    <xsl:value-of select="$content/.."/>
    <xsl:value-of select="substring-after($external-uri,$external-uri)"/>
    -->
    <xsl:choose>
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
        </div>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Links in content (function descriptions and list page intros) may need to be rewritten
       to include the current explicitly specified version -->
  <xsl:template match="x:a/@href[starts-with(.,'/')]">
    <xsl:attribute name="href" select="concat($version-prefix,.)"/>
  </xsl:template>

  <!-- Prepend the appropriate server name to the search form target -->
  <xsl:template match="@ml:action">
    <xsl:attribute name="action">
      <xsl:value-of select="$srv:main-server"/>
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <!-- Make search stick to the current API version -->
  <xsl:template match="x:input[@name eq $set-version-param-name]/@ml:value">
    <xsl:attribute name="value">
      <xsl:value-of select="$api:version"/>
    </xsl:attribute>
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
            <xsl:sequence select="concat('/', $version)"/>
          </xsl:template>


          <xsl:template name="reset-global-toc-vars">
            var functionPageBucketId = "<xsl:apply-templates mode="function-bucket-id" select="$content/api:function-page/api:function[1]/@bucket
                                                                                             | $content/api:list-page/@category-bucket"/>";
            var tocSectionLinkSelector = "<xsl:apply-templates mode="toc-section-link-selector" select="$content/*"/>";
          </xsl:template>

          <!-- ID for function buckets is the bucket display name minus spaces; see render-toc.xsl -->
          <xsl:template mode="function-bucket-id" match="@*">
            <xsl:value-of select="translate($version-prefix,'/.','v-')"/>
            <xsl:text>_</xsl:text>
            <xsl:value-of select="translate(.,' ','')"/>
          </xsl:template>


          <xsl:template mode="toc-section-link-selector" match="api:function-page">
            <xsl:text>.scrollable_section a[href='</xsl:text>
            <xsl:value-of select="$version-prefix"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="api:function[1]/@lib"/>
            <xsl:text>']</xsl:text>
          </xsl:template>

          <xsl:template mode="toc-section-link-selector" match="guide">
            <xsl:text>.scrollable_section a[href='</xsl:text>
            <xsl:value-of select="concat($version-prefix, ml:external-uri($content))"/>
            <xsl:text>']</xsl:text>
          </xsl:template>

          <xsl:template mode="toc-section-link-selector" match="api:list-page">
            <xsl:text>#</xsl:text>
            <xsl:value-of select="translate($version-prefix,'/.','v-')"/> <!-- might be empty -->
            <xsl:text>_</xsl:text>
            <xsl:value-of select="@container-toc-section-id"/>
            <xsl:text> >:first-child</xsl:text>
          </xsl:template>

          <!-- On the main docs page, just let the first tab be selected by default. -->
          <xsl:template mode="toc-section-link-selector" match="api:docs-page"/>


  <xsl:template mode="page-title" match="api:docs-page">
    <xsl:value-of select="$site-title"/>
  </xsl:template>

  <xsl:template mode="page-specific-title" match="api:list-page">
    <xsl:value-of select="@title"/>
  </xsl:template>


  <!-- currently not used -->
  <xsl:template match="ml:page-heading">
    <h2>
      <xsl:apply-templates mode="api-page-heading" select="$content/*"/>
    </h2>
  </xsl:template>

          <xsl:template mode="api-page-heading" match="*">
            <xsl:apply-templates mode="page-specific-title" select="."/>
          </xsl:template>

          <xsl:template mode="api-page-heading" match="api:function-page">
            <xsl:variable name="name" select="api:function[1]/@fullname"/>
            <xsl:variable name="prefix" select="substring-before($name,':')"/>
            <xsl:variable name="local"  select="substring-after ($name,':')"/>
            <a href="{$version-prefix}/{$prefix}" class="function_prefix">
              <xsl:value-of select="$prefix"/>
            </a>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="$local"/>
          </xsl:template>


  <xsl:template mode="page-content" match="api:docs-page">
    <div>
      <h2>
        <xsl:apply-templates mode="page-title" select="."/>
      </h2>
      <xsl:apply-templates mode="docs-page" select="$doc-list-config/*"/>
    </div>
  </xsl:template>

          <xsl:template mode="docs-page" match="group" priority="2">
            <h3><xsl:value-of select="@name"/></h3>
            <xsl:next-match/>
          </xsl:template>

          <xsl:template mode="docs-page" match="group | unnamed-group" priority="1">
            <ul class="doclist">
              <xsl:apply-templates mode="docs-list-item" select="*"/>
            </ul>
          </xsl:template>

                  <xsl:template mode="docs-list-item" match="*"/>
                  <xsl:template mode="docs-list-item" match="entry[url/@version = $api:version]
                                                           | guide[api:guide-info(@url-name)]">
                    <xsl:variable name="href">
                      <xsl:apply-templates mode="docs-page-entry-href" select="."/>
                    </xsl:variable>
                    <xsl:variable name="title">
                      <xsl:apply-templates mode="docs-page-entry-title" select="."/>
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
                        <xsl:apply-templates mode="docs-page-entry-description" select="."/>
                      </div>
                    </li>
                  </xsl:template>

                          <!-- Strip out phrases that don't apply to older server versions -->
                          <xsl:template mode="docs-page-entry-description" match="added-in[$api:version lt @version]"/>


                          <xsl:template mode="docs-page-entry-href" match="guide">
                            <xsl:value-of select="$version-prefix"/>
                            <xsl:value-of select="api:guide-info(@url-name)/@href"/>
                          </xsl:template>

                                  <xsl:function name="api:guide-info" as="element()?">
                                    <xsl:param name="url-name" as="attribute()"/>
                                    <xsl:sequence select="$content/*/api:user-guide[@href/ends-with(.,$url-name/concat('/',.))]"/>
                                  </xsl:function>

                          <xsl:template mode="docs-page-entry-href" match="entry[url]">
                            <xsl:value-of select="url[@version eq $api:version]/@href"/>
                          </xsl:template>


                          <xsl:template mode="docs-page-entry-title" match="guide">
                            <xsl:value-of select="api:guide-info(@url-name)/@display"/>
                          </xsl:template>

                          <xsl:template mode="docs-page-entry-title" match="entry">
                            <xsl:value-of select="@title"/>
                          </xsl:template>


  <xsl:template mode="page-content" match="api:list-page"><!-- | api:docs-page">-->
    <xsl:variable name="docs" as="element()*">
      <xsl:apply-templates mode="list-page-docs" select="."/>
    </xsl:variable>
    <div>
      <xsl:apply-templates mode="pjax_enabled-class-att" select="."/>
      <h2>
        <xsl:apply-templates mode="list-page-heading" select="."/>
      </h2>
      <xsl:apply-templates mode="list-page-intro" select="."/>
      <div class="doclist">
        <h2>&#160;</h2>
        <span class="amount">
          <xsl:variable name="count" select="count($docs)"/>
          <xsl:value-of select="$count"/>
          <xsl:text> </xsl:text>
          <xsl:apply-templates mode="list-page-item-type" select="."/>
          <xsl:if test="$count gt 1">s</xsl:if>
        </span>
        <table class="documentsTable">
          <colgroup>
            <col class="col1"/>
            <col class="col2"/>
          </colgroup>
          <thead>
            <tr>
              <th>
               <xsl:apply-templates mode="list-page-col1-heading" select="."/>
              </th>
              <th>Description</th>
              <xsl:apply-templates mode="list-page-col3-th" select="."/>
            </tr>
          </thead>
          <tbody>
            <xsl:apply-templates mode="list-page-entry" select="$docs"/>
          </tbody>
        </table>
      </div>
    </div>
  </xsl:template>

          <!-- Disable PJAX on User Guide links, because the large pages tend to break the browser -->
          <xsl:template mode="pjax_enabled-class-att" match="api:docs-page"/>
          <xsl:template mode="pjax_enabled-class-att" match="*">
            <xsl:attribute name="class">pjax_enabled</xsl:attribute>
          </xsl:template>

          <xsl:template mode="list-page-col3-th" match="*"/>
          <xsl:template mode="list-page-col3-th" match="api:docs-page">
            <th>PDF</th>
          </xsl:template>

          <xsl:template mode="list-page-docs" match="api:list-page">
            <xsl:sequence select="api:list-entry"/>
          </xsl:template>


          <xsl:template mode="list-page-intro" match="api:list-page">
            <xsl:apply-templates select="api:intro/node()"/>
          </xsl:template>

          <xsl:template mode="list-page-intro" match="api:docs-page"/>


          <xsl:template mode="list-page-item-type" match="api:list-page" >function</xsl:template>
          <xsl:template mode="list-page-item-type" match="api:docs-page">document</xsl:template>


          <xsl:template mode="list-page-col1-heading" match="api:list-page" >Function name</xsl:template>
          <xsl:template mode="list-page-col1-heading" match="api:docs-page">Title</xsl:template>


          <xsl:template mode="list-page-heading" match="api:docs-page">
            <xsl:value-of select="$site-title"/>
          </xsl:template>

          <!-- By default, just display the page title -->
          <xsl:template mode="list-page-heading" match="api:list-page">
            <xsl:apply-templates mode="page-specific-title" select="."/>
          </xsl:template>

          <!-- But for function category pages, include a link back to the main lib page -->
          <!-- ASSUMPTION: URL for function category pages follows this two-step format: "/cts/geospatial"
               ASSUMPTION: Heading for function category pages follows this format:      "cts functions (Geospatial)"
                                                                                  (i.e. first word is the lib prefix) -->
          <xsl:template mode="list-page-heading" match="api:list-page[@type eq 'function-category']">
            <xsl:variable name="heading">
              <xsl:next-match/>
            </xsl:variable>
            <!-- in case spell-lib is the library, get the path from the current URL, not the heading -->
            <a href="{$version-prefix}/{substring-before(substring-after(ml:external-uri(.),'/'),'/')}">
              <xsl:value-of select="substring-before($heading,' ')"/>
            </a>
            <xsl:text> </xsl:text>
            <xsl:value-of select="substring-after($heading,' ')"/>
          </xsl:template>


          <xsl:template mode="list-page-entry" match="api:list-entry">
            <tr>
              <td style="white-space: nowrap;">
                <a href="{$version-prefix}/{api:name}">
                  <xsl:if test="api:name/@indent">
                    <xsl:attribute name="class" select="'indented_function'"/>
                  </xsl:if>
                  <xsl:value-of select="api:name"/>
                </a>
              </td>
              <td>
                <xsl:apply-templates select="api:description/node()"/>
              </td>
            </tr>
          </xsl:template>


          <xsl:template mode="list-page-entry" match="entry | guide">
            <tr>
              <td style="white-space: nowrap;">
                <xsl:variable name="href">
                  <xsl:apply-templates mode="list-page-entry-href" select="."/>
                </xsl:variable>
                <a href="{$href}">
                  <xsl:apply-templates mode="list-page-entry-title" select="."/>
                </a>
              </td>
              <td>
                <xsl:apply-templates mode="list-page-entry-description" select="."/>
              </td>
              <td>
                <xsl:apply-templates mode="list-page-pdf-link" select="."/>
              </td>
            </tr>
          </xsl:template>

                  <!-- Strip out phrases that don't apply to older server versions -->
                  <xsl:template mode="list-page-entry-description" match="added-in[$api:version lt @version]"/>

                  <xsl:template mode="list-page-pdf-link" match="*">&#160;</xsl:template>
                  <xsl:template mode="list-page-pdf-link" match="guide">
                    <xsl:variable name="href">
                      <xsl:apply-templates mode="list-page-entry-href" select="."/>
                      <xsl:text>.pdf</xsl:text>
                    </xsl:variable>
                    <xsl:variable name="title">
                      <xsl:apply-templates mode="list-page-entry-title" select="."/>
                      <xsl:text> (PDF)</xsl:text>
                    </xsl:variable>
                    <a href="{$href}">
                      <img src="/media/pdf_icon.gif" title="{$title}" alt="{$title}" height="25" width="25"/> 
                    </a>
                  </xsl:template>


                  <xsl:template mode="list-page-entry-href" match="guide">
                    <xsl:value-of select="$version-prefix"/>
                    <xsl:value-of select="api:guide-info(@url-name)/@href"/>
                  </xsl:template>


                  <!-- Prefix local URLs with the version prefix (when applicable) -->
                  <xsl:template mode="list-page-entry-href" match="entry[@href/starts-with(.,'/')]">
                    <xsl:value-of select="$version-prefix"/>
                    <xsl:value-of select="@href"/>
                  </xsl:template>

                  <xsl:template mode="list-page-entry-href" match="entry[url]">
                    <xsl:value-of select="url[@version eq $api:version]/@href"/>
                  </xsl:template>

                  <xsl:template mode="list-page-entry-href" match="entry">
                    <xsl:value-of select="@href"/>
                  </xsl:template>


                  <xsl:template mode="list-page-entry-title" match="guide">
                    <xsl:value-of select="api:guide-info(@url-name)/@display"/>
                  </xsl:template>

                  <xsl:template mode="list-page-entry-title" match="entry">
                    <xsl:value-of select="@title"/>
                  </xsl:template>



  <xsl:template mode="page-content" match="api:function-page">
    <xsl:if test="$show-alternative-functions">
      <xsl:variable name="other-matches" select="api:get-matching-functions(api:function[1]/@name)/api:function-page except ."/>
      <xsl:if test="$other-matches">
        <p class="didYouMean">
          <xsl:text>Did you mean </xsl:text>
          <xsl:for-each select="$other-matches">
            <xsl:variable name="fullname" select="api:function[1]/@fullname"/>
            <a href="{$version-prefix}/{$fullname}">
              <xsl:value-of select="$fullname"/>
            </a>
            <xsl:if test="position() ne last()"> or </xsl:if>
          </xsl:for-each>
          <xsl:text>?</xsl:text>
        </p>
      </xsl:if>
    </xsl:if>
    <div>
      <xsl:apply-templates mode="pjax_enabled-class-att" select="."/>
      <h2>
        <xsl:apply-templates mode="api-page-heading" select="."/>
      </h2>
      <xsl:apply-templates select="api:function"/>
    </div>
  </xsl:template>

          <xsl:template match="api:function">
            <!-- Workaround for "not a bug" #13495 (automatic setting of xml:space="preserve" on <pre> thanks to application of the XHTML schema to the stylesheet) -->
            <xsl:element name="pre">
              <code>
                <xsl:value-of select="@fullname"/>
                <xsl:text>(</xsl:text>
                <xsl:if test="api:params/api:param">
                  <xsl:text>&#xA;</xsl:text>
                </xsl:if>
                <xsl:apply-templates mode="syntax" select="api:params/api:param"/>
                <xsl:text>) as </xsl:text>
                <xsl:value-of select="normalize-space(api:return)"/>
              </code>
            </xsl:element>
            <xsl:apply-templates select="(api:summary, api:params, api:usage, api:example)[normalize-space(.)]"/>
            <xsl:if test="position() ne last()"> <!-- if it's *:polygon() -->
              <br/>
              <br/>
              <hr/>
            </xsl:if>
          </xsl:template>

                  <xsl:template mode="syntax" match="api:param">
                    <xsl:text>   </xsl:text>
                    <xsl:if test="@optional eq 'true'">[</xsl:if>
                    <a href="#{@name}">
                      <xsl:text>$</xsl:text>
                      <xsl:value-of select="@name"/>
                    </a>
                    <xsl:text> as </xsl:text>
                    <xsl:value-of select="@type"/>
                    <xsl:if test="@optional eq 'true'">]</xsl:if>
                    <xsl:if test="position() ne last()">,</xsl:if>
                    <xsl:text>&#xA;</xsl:text>
                  </xsl:template>

                  <xsl:template match="api:summary">
                    <h3>Summary</h3>
                    <p>
                      <xsl:apply-templates/>
                    </p>
                  </xsl:template>

                  <xsl:template match="api:params">
                    <table class="parameters">
                      <thead>
                        <tr>
                          <th scope="colgroup" colspan="2">Parameters</th>
                        </tr>
                      </thead>
                      <tbody>
                        <xsl:apply-templates select="api:param"/>
                      </tbody>
                    </table>
                  </xsl:template>

                          <xsl:template match="api:param">
                            <tr>
                              <td>
                                <!--
                                <a name="{@name}"/>
                                -->
                                <xsl:text>$</xsl:text>
                                <xsl:value-of select="@name"/>
                              </td>
                              <td>
                                <xsl:apply-templates/>
                              </td>
                            </tr>
                          </xsl:template>

                  <xsl:template match="api:usage">
                    <h3>Usage notes</h3>
                    <xsl:apply-templates/>
                  </xsl:template>

                          <xsl:template match="api:schema-info">
                            <p>The structure of the XML node returned is as follows:</p>
                            <dl>
                              <xsl:apply-templates select="api:element"/>
                            </dl>
                          </xsl:template>

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
                    <xsl:element name="pre">
                      <code>
                        <div class="example">
                          <!-- Move the <pre> ID to its parent, so it doesn't get stripped
                               off by the syntax-highlighting code (thereby breaking any links to it). -->
                          <xsl:copy-of select="((pre|pre/a)/@id)[1]"/>
                          <xsl:apply-templates/>
                        </div>
                      </code>
                    </xsl:element>
                  </xsl:template>

                          <!-- Strip the @id off the example pre (because we've reassigned it) -->
                          <xsl:template match="api:example/pre  /@id
                                             | api:example/pre/a/@id"/>


  <!-- Disable the body class stuff -->
  <xsl:template mode="body-class
                      body-class-extra" match="*"/>



  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="ml:external-uri-api($node)"/>
  </xsl:function>

  <!-- ASSUMPTION: This is only called on version-less paths (as they appear in the XML TOCs). -->
  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:variable name="version-path" select="concat('/apidoc/', $api:version)"/>
    <xsl:value-of>
      <xsl:value-of select="$version-path"/>
      <xsl:value-of select="if ($doc-path eq '/') then '/index.xml' else concat($doc-path,'.xml')"/>
    </xsl:value-of>
  </xsl:function>

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
