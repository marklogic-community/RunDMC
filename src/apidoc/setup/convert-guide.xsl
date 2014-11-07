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
    <xsl:variable name="lists-captured">
      <xsl:apply-templates mode="capture-lists"
                           select="$sections-captured"/>
    </xsl:variable>
    <!-- Merge adjacent Code samples -->
    <xsl:variable name="code-merged">
      <xsl:apply-templates mode="merge-code-examples"
                           select="$lists-captured"/>
    </xsl:variable>
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
          <xsl:copy-of select="guide-title | title"/>
          <xsl:copy-of select="guide:metadata(.)"/>
          <xsl:copy-of select="chapter-list"/>
          <!-- Last step: add the XHTML namespace -->
          <xsl:copy-of select="stp:node-to-xhtml($converted-content)"/>
        </xsl:copy>
      </xsl:for-each>
    </xsl:result-document>
    <xsl:if test="$DEBUG_GROUPING">
      <xsl:value-of
          select="xdmp:document-insert(
                  concat('/DEBUG/sections-captured',$OUTPUT-URI),
                  $sections-captured)"/>
      <xsl:value-of
          select="xdmp:document-insert(
                  concat('/DEBUG/lists-captured'   ,$OUTPUT-URI),
                  $lists-captured)"/>
      <xsl:value-of
          select="xdmp:document-insert(
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

  <xsl:template mode="capture-lists" match="@* | node()">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="capture-lists-content" select="."/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="capture-lists-content" match="*">
    <xsl:apply-templates mode="capture-lists"/>
  </xsl:template>

  <xsl:template mode="capture-lists-content"
                match="div | CELL">
    <xsl:for-each-group select="*"
                        group-adjacent="guide:is-part-of-list(.)
                                        and not(self::div or self::CELL)">
      <xsl:apply-templates mode="outer-list" select="."/>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template mode="outer-list" match="Number">
    <ol>
      <xsl:for-each-group select="current-group()"
                          group-starting-with="Number">
        <li>
          <xsl:variable name="nested-bullets-captured" as="element()*">
            <xsl:call-template name="capture-nested-bullets"/>
          </xsl:variable>
          <!--
              ASSUMPTION: If there's a nested NumberA list,
              then it comprises the rest of this list item.
          -->
          <xsl:variable name="first-sub-item"
                        select="$nested-bullets-captured[self::NumberA][1]"/>
          <xsl:for-each-group select="$nested-bullets-captured"
                              group-starting-with="NumberA[. is $first-sub-item]">
            <xsl:apply-templates mode="inner-numbered-list" select="."/>
          </xsl:for-each-group>
        </li>
      </xsl:for-each-group>
    </ol>
  </xsl:template>

  <xsl:template mode="inner-numbered-list" match="NumberA">
    <ol>
      <xsl:for-each-group select="current-group()"
                          group-starting-with="NumberA">
        <li>
          <xsl:apply-templates mode="capture-lists" select="current-group()"/>
        </li>
      </xsl:for-each-group>
    </ol>
  </xsl:template>

  <xsl:template mode="outer-list" match="Body-bullet">
    <ul>
      <xsl:for-each-group select="current-group()"
                          group-starting-with="Body-bullet">
        <li>
          <xsl:call-template name="capture-nested-bullets"/>
        </li>
      </xsl:for-each-group>
    </ul>
  </xsl:template>

  <xsl:template name="capture-nested-bullets">
    <!--
        ASSUMPTION: each second-level bulleted list item consists of
        just one element (Body-bullet-2);
        they don't have subsequent paragraphs.
    -->
    <xsl:for-each-group select="current-group()"
                        group-adjacent="exists(self::Body-bullet-2)">
      <xsl:apply-templates mode="inner-list" select="."/>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template mode="inner-list" match="Body-bullet-2">
    <ul>
      <xsl:for-each select="current-group()">
        <li>
          <xsl:apply-templates mode="capture-lists" select="."/>
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <xsl:template mode="outer-list" match="Note[guide:starts-list(.)]">
    <NoteWithList>
      <xsl:call-template name="capture-nested-bullets"/>
    </NoteWithList>
  </xsl:template>

  <!-- If not part of a list, just copy the group through -->
  <xsl:template mode="outer-list
                      inner-list
                      inner-numbered-list" match="*">
    <xsl:apply-templates mode="capture-lists" select="current-group()"/>
  </xsl:template>

  <xsl:template mode="merge-code-examples" match="node()">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="merge-code-examples-content" select="."/>
    </xsl:copy>
    <xsl:apply-templates mode="merge-code-examples-after" select="."/>
  </xsl:template>

  <xsl:template mode="merge-code-examples-content" match="*">
    <xsl:apply-templates mode="merge-code-examples"/>
  </xsl:template>

  <xsl:template mode="merge-code-examples-content" match="li | div | CELL">
    <!-- Merge adjacent Code elements -->
    <xsl:for-each-group select="*"
                        group-adjacent="exists(self::Code)">
      <xsl:apply-templates mode="code-or-not" select="."/>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template mode="code-or-not" match="Code">
    <Code>
      <!-- Process the content of the adjacent Code elements -->
      <xsl:apply-templates mode="merge-code-examples"
                           select="current-group()/node()"/>
    </Code>
  </xsl:template>

  <xsl:template mode="code-or-not" match="*">
    <xsl:apply-templates mode="merge-code-examples"
                         select="current-group()"/>
  </xsl:template>

  <!-- By default, don't add anything after -->
  <xsl:template mode="merge-code-examples-after"
                match="node()"/>

  <!--
       Add a marker signifying we want to preserve the whitespace
       at the beginning of this Code element
       (as it's a subsequent adjacent one, which will be merged into the previous).
  -->
  <xsl:template mode="merge-code-examples-after"
                match="Code[preceding-sibling::*[1][self::Code]]/A[1]">
    <PRESERVE_FOLLOWING_WHITESPACE/>
  </xsl:template>

</xsl:stylesheet>
