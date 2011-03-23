<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp api">

  <xsl:import href="../../view/page.xsl"/>
  <xsl:import href="xquery-imports.xsl"/>

  <xsl:variable name="site-title" select="'MarkLogic API Documentation'"/>

  <xsl:variable name="template"   select="u:get-doc('/apidoc/config/template.xhtml')"/>

  <xsl:template match="ml:api-toc">
    <div id="apidoc_toc">
      <script type="text/javascript">
        window.onbeforeunload = function () {
            // Get current TOC scroll position
            $.cookie("tocScroll", $("#sub").scrollTop(), { expires: 7 });
        }

        $('#apidoc_toc').load('<xsl:value-of select="$api:toc-url"/>', function() {
          $("#sub").scrollTop($.cookie("tocScroll"));
          $("#sub a[href='/<xsl:value-of select="substring-after(ml:external-uri($content),'/')"/>']").addClass("currentPage");
        });
      </script>
    </div>
  </xsl:template>

  <xsl:template mode="page-specific-title" match="api:function-list-page">
    <xsl:value-of select="@prefix"/>
    <xsl:text> functions</xsl:text>
  </xsl:template>

  <xsl:template mode="page-specific-title" match="api:function-page">
    <xsl:value-of select="api:function[1]/@fullname"/>
  </xsl:template>

  <xsl:template mode="page-content" match="api:function-list-page">
    <!--
    <div class="downloads">
    -->
    <div class="doclist">
      <h2>&#160;</h2>
      <span class="amount">
        <xsl:variable name="count" select="count(api:function-listing)"/>
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
          <xsl:apply-templates select="api:function-listing"/>
        </tbody>
      </table>
    </div>
  </xsl:template>

          <xsl:template match="api:function-listing">
            <tr>
              <td>
                <a href="/{api:name}">
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
      <xsl:value-of select="(api:function/@fullname)[1]"/> <!-- two are present if *:polygon() -->
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
                      <xsl:apply-templates/>
                    </div>
                  </xsl:template>

  <!-- Make everything a "main page" -->
  <xsl:template mode="body-class" match="*">main_page</xsl:template>


  <!-- Account for "/apidoc" prefix in internal/external URI mappings -->
  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:variable name="doc-path" select="base-uri($node)"/>
    <xsl:sequence select="if ($doc-path eq '/apidoc/index.xml') then '/' else substring-before(substring-after($doc-path,'/apidoc'), '.xml')"/>
  </xsl:function>

  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:sequence select="if ($doc-path eq '/') then '/apidoc/index.xml' else concat('/apidoc', $doc-path, '.xml')"/>
  </xsl:function>

  <!-- Don't ever add any special CSS classes -->
  <xsl:template mode="body-class-extra" match="*"/>

</xsl:stylesheet>
