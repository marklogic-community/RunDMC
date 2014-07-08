<xsl:stylesheet version="2.0"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:guide="http://marklogic.com/rundmc/api/guide"
                xmlns:map="http://marklogic.com/xdmp/map"
                xmlns:ml="http://developer.marklogic.com/site/internal"
                xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
                xmlns:x="http://www.w3.org/1999/xhtml"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs api xdmp map x raw ml">

  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api"
      href="/apidoc/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/guide"
      href="/apidoc/setup/guide.xqm"/>
  <xdmp:import-module
      href="/apidoc/setup/raw-docs-access.xqy"
      namespace="http://marklogic.com/rundmc/raw-docs-access"/>

  <xsl:output indent="no"/>

  <!-- Only set to true in development, not in production. -->
  <xsl:variable name="convert-at-render-time" select="doc-available('/apidoc/DEBUG.xml') and doc('/apidoc/DEBUG.xml') eq 'yes'"/>

  <xsl:variable name="docs-page"
                select="doc(
                        concat(
                        api:version-dir($api:version),
                        'index.xml'))/api:docs-page"/>

  <xsl:variable name="auto-links"
                select="$docs-page/auto-link"/>

  <!-- TODO use xsl:copy-of to make this more efficient, per bug 25175
 <xsl:variable name="other-guide-listings">
         <xsl:copy-of select="$docs-page/api:user-guide
                 [not(@href eq api:external-uri($content))]"/>
 </xsl:variable>
  -->
  <!--
      The above broke the guide links, so reverting this back.
      I don't yet understand why it broke them.
  -->
 <xsl:variable name="other-guide-listings" select="$docs-page/api:user-guide
         [not(@href eq api:external-uri($content))]"/>


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
              select="guide:convert-uri(base-uri(current()))/*/node()"/>
        </xsl:otherwise>
      </xsl:choose>
    </div>
    <xsl:apply-templates mode="chapter-next-prev" select="@previous,@next"/>
    <!-- "Next" link on Table of Contents (guide) page -->
    <xsl:apply-templates mode="guide-next" select="@next"/>
  </xsl:template>

  <!-- Guide title -->
  <xsl:template mode="guide" match="/*/guide-title">
    <!-- Add a PDF link at the top of each guide (and chapter), before the <h1> -->
    <a href="{api:external-guide-uri(/)}.pdf" class="guide-pdf-link" target="_blank">
      <img src="/images/i_pdf.png" title="{.} (PDF)" alt="{.} (PDF)" height="25" width="25">
        <!-- Shrink the PDF icon size if we're on a chapter page -->
        <xsl:if test="parent::chapter">
          <xsl:attribute name="class" select="'printerFriendly'"/> <!-- same padding, etc., as printer icon -->
          <xsl:attribute name="height" select="16"/>
          <xsl:attribute name="width" select="16"/>
        </xsl:if>
      </img>
    </a>
    <!-- printer-friendly link on chapter pages -->
    <xsl:if test="parent::chapter">
      <xsl:apply-templates mode="print-friendly-link" select="."/>
    </xsl:if>
    <h1>
      <xsl:apply-templates mode="guide-heading-content" select="."/>
    </h1>
    <xsl:apply-templates mode="chapter-next-prev" select="../@previous, ../@next"/>
  </xsl:template>

          <xsl:function name="api:external-guide-uri" as="xs:string">
            <xsl:param name="guide-doc" as="document-node()"/>
            <xsl:sequence
                select="api:external-uri-with-prefix(
                        $version-prefix, $guide-doc/*/@guide-uri)"/>
          </xsl:function>

          <!-- Don't link to the guide root when we're already on it -->
          <xsl:template mode="guide-heading-content" match="/guide/guide-title">
            <xsl:apply-templates mode="guide-title" select="."/>
          </xsl:template>

          <!-- Make the guide heading a link when we're on a chapter page -->
          <xsl:template mode="guide-heading-content" match="/chapter/guide-title">
            <a href="{api:external-guide-uri(/)}">
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


          <!-- Only show the next/prev links on chapter pages (and just "Next" on the guide page) -->
          <xsl:template mode="chapter-next-prev
                              guide-next" match="@*"/>
          <xsl:template mode="guide-next" match="guide/@next">
            <xsl:call-template name="guide-next"/>
          </xsl:template>
          <xsl:template mode="chapter-next-prev" match="chapter/@next | chapter/@previous" name="guide-next">
            <div class="{local-name(.)}Chapter">
              <a href="{api:external-uri-with-prefix($version-prefix, .)}">
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


  <!-- Resolve the relative image URI according to the current guide -->
  <xsl:template mode="guide-att-value" match="x:img/@src">
    <xsl:value-of select="concat(api:guide-image-dir(base-uri(.)), .)"/>
  </xsl:template>

  <!-- Automatically convert italicized guide references to links, but not the
       ones that are immediately preceded by "in the", in which case we
       assume a more specific section link was already provided. -->
  <xsl:template mode="guide" match="x:em[api:config-for-title(.)]
          [not(preceding-sibling::node()[1][self::text()][normalize-space(.)
               eq 'in the'])]">
    <a href="{$version-prefix}{api:config-for-title(.)/@href}">
      <xsl:next-match/>
    </a>
  </xsl:template>

  <xsl:function name="api:config-for-title" as="element()?">
    <xsl:param name="link-text" as="xs:string"/>
    <xsl:variable name="title" select="api:normalize-text($link-text)"/>
    <xsl:sequence select="$other-guide-listings[(@display|alias)
                          /api:normalize-text(.) = $title] |
                          $auto-links[alias/api:normalize-text(.) = $title]"/>
  </xsl:function>

  <xsl:function name="api:normalize-text" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:sequence select="normalize-space(lower-case(
                          translate($text,'&#160;',' ')))"/>
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
