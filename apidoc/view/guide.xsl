<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:map="http://marklogic.com/xdmp/map"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:x="http://www.w3.org/1999/xhtml"
  xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs api xdmp map x raw ml">

  <xdmp:import-module href="/apidoc/setup/raw-docs-access.xqy" namespace="http://marklogic.com/rundmc/raw-docs-access"/>

  <xsl:output indent="no"/>

  <!-- Only set to true in development, not in production. -->
  <xsl:variable name="convert-at-render-time" select="doc-available('/apidoc/DEBUG.xml') and doc('/apidoc/DEBUG.xml') eq 'yes'"/>

  <xsl:variable name="docs-page" select="doc(concat('/apidoc/',$api:version,'/index.xml'))/api:docs-page"/>

  <xsl:variable name="auto-links" select="$docs-page/auto-link"/>

  <xsl:variable name="other-guide-listings" select="$docs-page/api:user-guide[not(@href eq ml:external-uri($content))]"/>

  <!-- Disable comments on User Guide pages -->
  <xsl:template mode="comment-section" match="/guide"/>

  <xsl:template mode="page-content" match="/guide">
    <div class="userguide">
      <xsl:choose>
        <!-- The normal case: the guide is already converted (at "build time", i.e. the setup phase). -->
        <xsl:when test="not($convert-at-render-time)">
          <xsl:apply-templates mode="guide"/>
        </xsl:when>
        <!-- For development purposes only. Normally, assume that the guide is already converted (in the setup phase). -->
        <xsl:otherwise>
          <p style="position:fixed; color: red"><br/><br/>WARNING: This was converted directly from the raw docs database for convenience in development.
             Set the $convert-at-render-time flag to false in production (and this warning will go away).</p>
          <!-- Convert and render the guide by directly calling the setup/conversion code -->
          <xsl:apply-templates mode="guide"  select="xdmp:xslt-invoke('../setup/convert-guide.xsl',
                                                                      $raw:guide-docs[raw:target-guide-uri(.) eq base-uri(current())])
                                                     /guide/node()"/>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <!-- Guide title -->
  <xsl:template mode="guide" match="guide/title">
    <!-- Add a PDF link at the top of each guide, before the <h1> -->
    <a href="{$version-prefix}{ml:external-uri(.)}.pdf" class="guide-pdf-link">
      <img src="/media/pdf_icon.gif" title="{.} (PDF)" alt="{.} (PDF)" height="25" width="25"/>
    </a>
    <h1>
      <xsl:value-of select="."/>
    </h1>
  </xsl:template>

  <xsl:template mode="guide" match="guide/info">
    <table class="guide_info">
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
    <xsl:apply-templates mode="guide-chapter-list" select="."/>
  </xsl:template>

  <xsl:template mode="guide-chapter-list" match="guide/info">
    <p>This guide includes the following sections:</p>
    <ul>
      <xsl:apply-templates mode="guide-chapter-list-item" select="../x:div[@class eq 'section']/x:h2/x:a"/>
    </ul>
  </xsl:template>

          <xsl:template mode="guide-chapter-list-item" match="x:a">
            <li>
              <a href="{@href}">
                <xsl:apply-templates/>
              </a>
            </li>
          </xsl:template>


  <!-- Resolve the relative image URI according to the current guide -->
  <xsl:template mode="guide-att-value" match="x:img/@src">
    <xsl:value-of select="concat(api:guide-image-dir(base-uri(.)), .)"/>
  </xsl:template>

  <!-- Automatically convert italicized guide references to links, but not the ones that are immediately preceded by "in the",
       in which case we assume a more specific section link was already provided. -->
  <xsl:template mode="guide" match="x:em[api:config-for-title(.)]
                                        [not(preceding-sibling::node()[1][self::text()][normalize-space(.) eq 'in the'])]">
    <a href="{$version-prefix}{api:config-for-title(.)/@href}">
      <xsl:next-match/>
    </a>
  </xsl:template>

          <xsl:function name="api:config-for-title" as="element()?">
            <xsl:param name="link-text" as="xs:string"/>
            <xsl:variable name="title" select="api:normalize-text($link-text)"/>
            <xsl:sequence select="$other-guide-listings[(@display|alias)/api:normalize-text(.) = $title] |
                                  $auto-links                    [alias /api:normalize-text(.) = $title]"/>
          </xsl:function>

                  <xsl:function name="api:normalize-text" as="xs:string">
                    <xsl:param name="text" as="xs:string"/>
                    <xsl:sequence select="normalize-space(lower-case(translate($text,'&#160;',' ')))"/>
                  </xsl:function>


  <!-- Boilerplate copying code -->
  <xsl:template mode="guide" match="node()">
    <xsl:apply-templates mode="guide-before" select="."/>
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:apply-templates mode="guide-add-att" select="."/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

          <xsl:template mode="guide-before" match="node()"/>

          <xsl:template mode="guide-add-att" match="*"/>

  <xsl:template mode="guide" match="@*">
    <xsl:attribute name="{name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates mode="guide-att-value" select="."/>
    </xsl:attribute>
  </xsl:template>

          <xsl:template mode="guide-att-value" match="@*">
            <xsl:value-of select="."/>
          </xsl:template>

</xsl:stylesheet>
