<xsl:stylesheet version="2.0"
                xmlns:guide="http://marklogic.com/rundmc/api/guide"
                xmlns:ml="http://developer.marklogic.com/site/internal"
                xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
                xmlns:stp="http://marklogic.com/rundmc/api/setup"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs raw ml">

  <xsl:import href="../view/page.xsl"/>

  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/guide"
      href="/apidoc/setup/guide.xqm"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/setup"
      href="/apidoc/setup/setup.xqm"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/raw-docs-access"
      href="/apidoc/setup/raw-docs-access.xqy"/>

  <xsl:output indent="no"/>

  <xsl:param name="OUTPUT-URI"
             as="xs:string"/>
  <xsl:param name="RAW-DOCS"
             as="document-node()+"/>
  <xsl:param name="FULLY-RESOLVED-TOP-LEVEL-HEADING-REFERENCES"
             as="xs:string+"/>

  <xsl:variable name="DEBUG_GROUPING"
                select="$convert-at-render-time"/>

  <xsl:template match="/">
    <!-- Capture section hierarchy -->
    <xsl:variable
        name="sections-captured"
        select="guide:sections(*)"/>
    <!-- Capture list hierarchy -->
    <xsl:variable name="lists-captured"
                  select="guide:lists($sections-captured)"/>
    <!-- Merge adjacent Code samples -->
    <xsl:variable name="code-merged" as="document-node()"
                  select="guide:code($lists-captured)"/>
    <!-- Main conversion of source elements to XHTML elements -->
    <xsl:variable name="converted-content">
      <!--
          Only copy the XML content for chapters.
          Guides just have some metadata (copied later below).
      -->
      <xsl:apply-templates select="$code-merged/chapter/XML"/>
    </xsl:variable>
    <!--
        We're reading from a doc in one database
        and writing to a doc in a different database, using a similar URI.
    -->
    <xsl:result-document href="{$OUTPUT-URI}">
      <xsl:for-each select="/guide | /chapter">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:copy-of select="guide-title|title"/>
          <xsl:copy-of select="stp:suggest(guide-title|title)"/>
          <xsl:copy-of select="guide:metadata(.)"/>
          <xsl:copy-of select="chapter-list"/>
          <!-- Last step: add the XHTML namespace -->
          <xsl:copy-of select="stp:node-to-xhtml($converted-content)"/>
        </xsl:copy>
      </xsl:for-each>
    </xsl:result-document>
    <xsl:if test="$DEBUG_GROUPING">
      <xsl:value-of
          select="ml:document-insert(
                  concat('/DEBUG/sections-captured',$OUTPUT-URI),
                  $sections-captured)"/>
      <xsl:value-of
          select="ml:document-insert(
                  concat('/DEBUG/lists-captured'   ,$OUTPUT-URI),
                  $lists-captured)"/>
      <xsl:value-of
          select="ml:document-insert(
                  concat('/DEBUG/code-merged'      ,$OUTPUT-URI),
                  $code-merged)"/>
    </xsl:if>
  </xsl:template>

  <!-- Don't need this attribute at this stage; only used to
       resolve URIs of images being copied over -->
  <xsl:template match="/*/@original-dir"/>

  <xsl:template match="pagenum | TITLE"/>

  <!--
      Heading-2MESSAGE case
      (priority should be greater than Heading-* case)
  -->
  <xsl:template match="Heading-2MESSAGE" priority="1">
    <xsl:variable name="id">
      <xsl:value-of select="normalize-space(.)"/>
    </xsl:variable>
    <xsl:variable name="href">
      <xsl:value-of select="guide:heading-2message-href($OUTPUT-URI, $id)"/>
    </xsl:variable>
    <!--
        Beware of changing this structure without updating
        the toc.xqm toc:guide-* functions, which depend on it.
    -->
    <a id="{$id}"/>
    <h3>
      <a href="{$href}" class="sectionLink">
        <xsl:value-of select="$id"/>
      </a>
    </h3>
  </xsl:template>

  <!-- Cause and Response headings for messages guide -->
  <xsl:template match="Simple-Heading-3">
    <h4>
      <xsl:value-of select="normalize-space(.)"/>
    </h4>
  </xsl:template>

  <xsl:template match="IMAGE">
    <img src="{@href}"/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:variable name="local-name"
                  select="local-name(.)"/>
    <xsl:variable name="is-heading"
                  select="starts-with($local-name, 'Heading-')"/>
    <xsl:variable name="new-name"
                  select="if ($is-heading) then () else guide:new-name(.)"/>
    <xsl:choose>

      <!-- Heading-* (except MESSAGE) case -->
      <xsl:when test="$is-heading">
        <xsl:copy-of select="guide:heading-anchor(., $local-name)"/>
      </xsl:when>

      <!-- Convert elements that should be converted -->
      <xsl:when test="$new-name">
        <xsl:element name="{$new-name}">
          <xsl:copy-of select="guide:attributes(@*)"/>
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:when>

      <!-- Do not copy, but keep processing. -->
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Copy attributes -->
  <xsl:template match="@*">
    <xsl:copy-of select="@*"/>
  </xsl:template>

  <!-- Copy these elements -->
  <xsl:template match="div | ul | ol | li | code">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="underline">
    <span class="underline">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- These lists are already well-structured and don't need to be captured -->
  <xsl:template match="BulletedList">
    <ul>
      <xsl:apply-templates select="Bulleted"/>
    </ul>
  </xsl:template>

  <xsl:template match="Bulleted">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="Note">
    <p class="note">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- we add this wrapper when capturing lists (see below) -->
  <xsl:template match="NoteWithList">
    <div class="note">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="NoteWithList/Note">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="Warning">
    <p class="warning">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!--
      Don't convert a single Body or CellBody child inside a CELL to a <p>.
      Just process contents.
  -->
  <xsl:template match="CELL[count(*) eq 1]/Body
                       | CELL[count(*) eq 1]/CellBody" priority="1">
    <xsl:apply-templates/>
  </xsl:template>


  <!-- The docapp code strips leading line breaks (and any preceding space) from each text node. Let's try that... -->
  <xsl:template match="text()">
    <xsl:value-of select="replace(., '^\s*\n', '')"/>
  </xsl:template>

  <!--
      Now that we're merging adjacent <Code> elements,
      let's be more discriminating about which whitespace characters we strip.
      In particular, preserve the whitespace that comes
      at the beginning of a merged Code element (see below).
  -->
  <xsl:template match="text()[
                       preceding-sibling::*[1][
                       . instance of element(PRESERVE_FOLLOWING_WHITESPACE)]]">
    <xsl:value-of select="."/>
  </xsl:template>

  <!--
      <!- - TODO: identify significant line breaks, e.g., in code examples, and modify rule(s) accordingly - ->
      <!- - Strip out line breaks - ->
      <xsl:template match="text()[not(ancestor::Code)]">
      <xsl:value-of select="replace(.,'&#xA;','')"/>
      </xsl:template>
      <!- - Strip out isolated line breaks in Code elements - ->
      <xsl:template match="Code/text()[not(normalize-space(.))]"/>
  -->

  <xsl:template match="A">
    <xsl:copy-of
        select="guide:anchor(
                $RAW-DOCS,
                $FULLY-RESOLVED-TOP-LEVEL-HEADING-REFERENCES,
                .)"/>
  </xsl:template>

  <xsl:template match="Hyperlink">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
