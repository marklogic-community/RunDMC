<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:u="http://marklogic.com/rundmc/util"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  xmlns:x="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="x xs ml xdmp api">

  <xsl:import href="../../view/page.xsl"/>
  <xsl:import href="xquery-imports.xsl"/>

  <!-- Include the version prefix (e.g., "/4.2") when explicitly specified; otherwise don't -->
  <!--
  <xsl:variable name="version-prefix" select="if (not($api:version-specified)) then '' else concat('/',$api:version-specified)"/>
  -->

  <!-- Alternative behavior: if current version is the default version (whether explicitly specified or not),
       then don't include the version prefix in links; see also $api:toc-url in data-access.xqy -->
  <xsl:variable name="version-prefix" select="if ($api:version eq $api:default-version) then '' else concat('/',$api:version-specified)"/>

  <xsl:variable name="versions" select="u:get-doc('/apidoc/config/server-versions.xml')/versions/version"/>

  <xsl:variable name="site-title" select="'MarkLogic API Documentation'"/>

  <xsl:variable name="site-url-for-disqus" select="'http://api.marklogic.com'"/>

  <xsl:variable name="template"   select="u:get-doc('/apidoc/config/template.xhtml')"/>

  <!-- Links in content (function descriptions and list page intros) may need to be rewritten
       to include the current explicitly specified version -->
  <xsl:template match="x:a/@href[starts-with(.,'/')]">
    <xsl:attribute name="href" select="concat($version-prefix,.)"/>
  </xsl:template>

  <xsl:template match="ml:version-list">
    <div id="version_list">
      <span>API Reference </span>
      <span class="version">
        <xsl:text>(version: </xsl:text>
        <xsl:apply-templates mode="version-list-item" select="$versions"/>
        <xsl:text>)</xsl:text>
      </span>
    </div>
  </xsl:template>

          <xsl:template mode="version-list-item" match="version">
            <a href="/{@number}">
              <xsl:apply-templates mode="version-selected-class" select="."/>
              <xsl:value-of select="@number"/>
            </a>
            <xsl:if test="position() ne last()"> | </xsl:if>
          </xsl:template>

                  <xsl:template mode="version-selected-class" match="version"/>
                  <xsl:template mode="version-selected-class" match="version[@number eq $api:version]">
                    <xsl:attribute name="class" select="'currentVersion'"/>
                  </xsl:template>


  <xsl:template match="ml:api-toc">
    <div id="apidoc_toc">
      <script type="text/javascript">
        window.onbeforeunload = function () {
            // Get current TOC scroll position
            $.cookie("tocScroll", $("#sub").scrollTop(), { expires: 7 });
        }

        $('#apidoc_toc').load('<xsl:value-of select="$api:toc-url"/>', function() {
          $("#sub").scrollTop($.cookie("tocScroll"));
          $("#sub a[href='<xsl:value-of select="$version-prefix"/><xsl:value-of select="ml:external-uri($content)"/>']").addClass("currentPage");
        });
      </script>
    </div>
  </xsl:template>

  <xsl:template mode="page-specific-title" match="api:list-page">
    <xsl:value-of select="@title"/>
  </xsl:template>

  <xsl:template mode="page-specific-title" match="api:function-page">
    <xsl:value-of select="api:function[1]/@fullname"/>
  </xsl:template>

  <xsl:template mode="page-content" match="api:list-page">
    <!--
    <div class="downloads">
    -->
    <h1>
      <xsl:apply-templates mode="list-page-heading" select="."/>
    </h1>
    <xsl:apply-templates select="api:intro"/>
    <div class="doclist">
      <h2>&#160;</h2>
      <span class="amount">
        <xsl:variable name="count" select="count(api:list-entry)"/>
        <xsl:value-of select="$count"/>
        <xsl:text> function</xsl:text>
        <xsl:if test="$count gt 1">s</xsl:if>
      </span>
      <table class="documentsTable">
        <colgroup>
          <col class="col1"/>
          <col class="col2"/>
        </colgroup>
        <thead>
          <tr>
            <th>Function name</th>
            <th>Description</th>
          </tr>
        </thead>
        <tbody>
          <xsl:apply-templates select="api:list-entry"/>
        </tbody>
      </table>
    </div>
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



          <xsl:template match="api:intro">
            <xsl:apply-templates/>
          </xsl:template>

          <xsl:template match="api:list-entry">
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


  <xsl:template mode="page-content" match="api:function-page">
    <h1>
      <xsl:variable name="name" select="api:function[1]/@fullname"/>
      <xsl:variable name="prefix" select="substring-before($name,':')"/>
      <xsl:variable name="local"  select="substring-after ($name,':')"/>
      <a href="{$version-prefix}/{$prefix}">
        <xsl:value-of select="$prefix"/>
      </a>
      <xsl:text>:</xsl:text>
      <xsl:value-of select="$local"/>
    </h1>
    <xsl:apply-templates select="api:function"/>
  </xsl:template>

          <xsl:template match="api:function">
            <code class="syntax">
              <strong>
                <xsl:value-of select="@fullname"/>
              </strong>
              <xsl:text>(</xsl:text>
              <xsl:if test="api:params/api:param">
                <xsl:text>&#xA;</xsl:text>
              </xsl:if>
              <xsl:apply-templates mode="syntax" select="api:params/api:param"/>
              <xsl:text>) as </xsl:text>
              <xsl:value-of select="normalize-space(api:return)"/>
            </code>
            <xsl:apply-templates select="api:summary, api:params, api:usage, api:example"/>
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
                    <h2>Summary</h2>
                    <xsl:apply-templates/>
                  </xsl:template>

                  <xsl:template match="api:params">
                    <h2>Parameters</h2>
                    <ol>
                      <xsl:apply-templates select="api:param"/>
                    </ol>
                  </xsl:template>

                          <xsl:template match="api:param">
                            <li class="parameter">
                              <a name="{@name}"/>
                              <code>
                                  <xsl:text>$</xsl:text>
                                  <xsl:value-of select="@name"/>
                              </code>
                              <xsl:text>: </xsl:text>
                              <xsl:apply-templates/>
                            </li>
                          </xsl:template>

                  <xsl:template match="api:usage">
                    <h2>Usage notes</h2>
                    <xsl:apply-templates/>
                  </xsl:template>

                  <xsl:template match="api:example">
                    <h2>Example</h2>
                    <div class="example">
                      <!-- Move the <pre> ID to its parent, so it doesn't get stripped
                           off by the syntax-highlighting code (thereby breaking any links to it). -->
                      <xsl:copy-of select="((pre|pre/a)/@id)[1]"/>
                      <xsl:apply-templates/>
                    </div>
                  </xsl:template>

                          <!-- Strip the @id off the example pre (because we've reassigned it) -->
                          <xsl:template match="api:example/pre  /@id
                                             | api:example/pre/a/@id"/>


  <!-- Make everything a "main page" -->
  <xsl:template mode="body-class" match="*">main_page</xsl:template>


  <!-- Account for "/apidoc" prefix in internal/external URI mappings -->
  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:variable name="doc-uri" select="base-uri($node)"/>

    <xsl:variable name="version" select="substring-before(substring-after($doc-uri,'/apidoc/'),'/')"/>
    <xsl:variable name="versionless-path" select="substring-after($doc-uri,concat('/apidoc/',$version))"/>

    <xsl:value-of>
      <!-- Map "/index.xml" to "/" and "/foo.xml" to "/foo" -->
      <xsl:value-of select="if ($versionless-path eq '/index.xml') then '/' else substring-before($versionless-path, '.xml')"/>
    </xsl:value-of>
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
