<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:my="http://localhost"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs raw my ml">

  <xsl:import href="../view/page.xsl"/>

  <xdmp:import-module href="/apidoc/setup/raw-docs-access.xqy" namespace="http://marklogic.com/rundmc/raw-docs-access"/>

  <xsl:output indent="no"/>

  <xsl:variable name="DEBUG_GROUPING" select="$convert-at-render-time"/>

  <xsl:param name="output-uri" select="raw:target-guide-uri(.)"/>

  <xsl:template match="/">
    <!-- Strip out unhelpful list containers -->
    <xsl:variable name="useless-containers-stripped">
      <xsl:apply-templates mode="strip-useless-containers" select="."/>
    </xsl:variable>
    <!-- Capture section hierarchy -->
    <xsl:variable name="sections-captured">
      <xsl:apply-templates mode="capture-sections" select="$useless-containers-stripped"/>
    </xsl:variable>
    <!-- Capture list hierarchy -->
    <xsl:variable name="lists-captured">
      <xsl:apply-templates mode="capture-lists" select="$sections-captured"/>
    </xsl:variable>
    <!-- Main conversion of source elements to XHTML elements -->
    <xsl:variable name="converted-content">
      <xsl:apply-templates select="$lists-captured/guide/node()"/>
    </xsl:variable>
    <!-- We're reading from a doc in one database and writing to a doc in a different database, using a similar URI -->
    <xsl:message>Outputting converted guide to: <xsl:value-of select="$output-uri"/></xsl:message>
    <xsl:result-document href="{$output-uri}">
      <guide>
        <title>
          <xsl:value-of select="/guide/title"/>
        </title>
        <!-- Last step: add the XHTML namespace -->
        <xsl:apply-templates mode="add-xhtml-namespace" select="$converted-content"/>
      </guide>
    </xsl:result-document>
    <xsl:if test="$DEBUG_GROUPING">
      <xsl:value-of select="xdmp:document-insert(concat('/DEBUG/sections-captured',$output-uri), $sections-captured)"/>
      <xsl:value-of select="xdmp:document-insert(concat('/DEBUG/lists-captured'   ,$output-uri),    $lists-captured)"/>
    </xsl:if>
  </xsl:template>

          <xsl:template mode="strip-useless-containers" match="@* | node()">
            <xsl:copy>
              <xsl:apply-templates mode="#current" select="@* | node()"/>
            </xsl:copy>
          </xsl:template>

          <!-- These container elements apparently add no value for list detection (they appear inconsistently) -->
          <xsl:template mode="strip-useless-containers" match="NumberList | NumberAList | WarningList">
            <xsl:apply-templates mode="#current"/>
          </xsl:template>


          <xsl:template mode="add-xhtml-namespace" match="@* | node()">
            <xsl:copy/>
          </xsl:template>

          <xsl:template mode="add-xhtml-namespace" match="*" priority="1">
            <xsl:element name="{local-name(.)}" namespace="http://www.w3.org/1999/xhtml">
              <xsl:apply-templates mode="#current" select="@* | node()"/>
            </xsl:element>
          </xsl:template>


  <!-- Don't need this attribute at this stage; only used to resolve URIs of images being copied over -->
  <xsl:template match="/guide/@original-dir"/>

  <xsl:template match="pagenum | TITLE"/>

  <xsl:template match="*[starts-with(local-name(.),'Heading-')]">
    <xsl:variable name="heading-level" select="1 + number(substring-after(local-name(.),'-'))"/>
    <xsl:element name="h{$heading-level}">
      <xsl:variable name="id">
        <xsl:apply-templates mode="heading-anchor-id" select="."/>
      </xsl:variable>
      <a id="{$id}" href="#{$id}" class="sectionLink">
        <xsl:value-of select="normalize-space(.)"/>
      </a>
    </xsl:element>
  </xsl:template>

          <!-- Use only the last A/@ID inside the heading, since all links get rewritten to the last one -->
          <xsl:template mode="heading-anchor-id" match="*">
            <xsl:value-of select="my:full-anchor-id(A[@ID][last()]/@ID)"/>
          </xsl:template>

          <!-- Base top-level anchor on the original file name (special case so no extraneous number ID is appended) -->
          <xsl:template mode="heading-anchor-id" match="Heading-1">
            <xsl:value-of select="my:anchor-id-for-top-level-heading(.)"/>
          </xsl:template>

                  <xsl:function name="my:anchor-id-for-top-level-heading">
                    <xsl:param name="heading-1" as="element(Heading-1)"/>
                    <xsl:sequence select="my:basename-stem($heading-1/ancestor::XML/@original-file)"/>
                  </xsl:function>

                          <xsl:function name="my:basename-stem">
                            <xsl:param name="url"/>
                            <xsl:sequence select="substring-before(tokenize($url,'/')[last()],'.xml')"/>
                          </xsl:function>


  <xsl:template match="IMAGE">
    <img src="{@href}"/>
  </xsl:template>

  <!-- By default, do *not* copy elements -->
  <xsl:template match="*">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Copy these elements (and their attributes) -->
  <xsl:template match="@* | div | ul | ol | li">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Convert elements that should be converted -->
  <xsl:template match="*[string(my:new-name(.))]">
    <xsl:element name="{my:new-name(.)}">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

          <xsl:function name="my:new-name">
            <xsl:param name="element"/>
            <xsl:apply-templates mode="new-name" select="$element"/>
          </xsl:function>

                  <!-- Some need to be set to lower-case -->
                  <xsl:template mode="new-name" match="TABLE | TH">
                    <xsl:value-of select="lower-case(local-name(.))"/>
                  </xsl:template>
                  <!-- Others need to be renamed -->
                  <xsl:template mode="new-name" match="title"   >h1</xsl:template>
                  <xsl:template mode="new-name" match="ROW"     >tr</xsl:template>
                  <xsl:template mode="new-name" match="CELL"    >td</xsl:template>
                  <xsl:template mode="new-name" match="Emphasis">em</xsl:template>
                  <xsl:template mode="new-name" match="Code
                                                     | CodeNoIndent">pre</xsl:template>
                  <xsl:template mode="new-name" match="Body
                                                     | CellBody
                                                     | Body-indent
                                                     | Body-indent-blockquote">p</xsl:template>

                  <!-- By default, we just strip the start & end tags out -->
                  <xsl:template mode="new-name" match="*"/>


  <xsl:template match="Note">
    <p class="note">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="Warning">
    <p class="warning">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- Don't convert a single Body or CellBody child inside a CELL to a <p>; just process contents -->
  <xsl:template match="CELL[count(*) eq 1]/Body
                     | CELL[count(*) eq 1]/CellBody" priority="1">
    <xsl:apply-templates/>
  </xsl:template>


  <!-- TODO: identify significant line breaks, e.g., in code examples, and modify rule(s) accordingly -->
  <!-- Strip out line breaks -->
  <xsl:template match="text()[not(ancestor::Code)]">
    <xsl:value-of select="replace(.,'&#xA;','')"/>
  </xsl:template>

  <!-- Strip out isolated line breaks in Code elements -->
  <xsl:template match="Code/text()[not(normalize-space(.))]"/>

  <!-- Since we rewrite all links to point to the last anchor, it's safe to remove all the anchors that aren't last. -->
  <xsl:template match="A[@ID][not(position() eq last())]"/>

  <xsl:template match="A">
    <a>
      <xsl:apply-templates select="@ID | @href"/>
      <xsl:apply-templates mode="guide-link-content" select="."/>
    </a>
  </xsl:template>

          <!-- Remove apostrophe delimiters when present -->
          <xsl:template mode="guide-link-content" match='A[starts-with(normalize-space(.), "&apos;")]' priority="1">
            <xsl:value-of select='substring-before(substring-after(normalize-space(.),"&apos;"),"&apos;")'/>
          </xsl:template>

          <!-- Remove "on page 32" verbiage -->
          <xsl:template mode="guide-link-content" match="A[contains(normalize-space(.), ' on page')]">
            <xsl:value-of select="substring-before(normalize-space(.), ' on page')"/>
          </xsl:template>

          <xsl:template mode="guide-link-content" match="A">
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:template>


          <xsl:template match="A/@ID">
            <xsl:attribute name="id" select="my:full-anchor-id(.)"/>
          </xsl:template>

                  <xsl:function name="my:full-anchor-id">
                    <xsl:param name="ID-att"/>
                    <xsl:sequence select="concat(my:anchor-id-for-top-level-heading($ID-att/ancestor::XML/div/Heading-1),'_',$ID-att)"/>
                  </xsl:function>


          <!-- Links within the same guide -->
          <xsl:template match="A/@href[contains(.,'#id(')]" priority="1">
            <xsl:variable name="guide" select="root(.)"/>
            <xsl:attribute name="href" select="concat('#', my:anchor-id-from-href(.,$guide))"/>
          </xsl:template>

          <!-- Links to other guides -->
          <xsl:template match="A/@href[starts-with(.,'../')]" priority="2">
            <xsl:variable name="guide" select="$raw:guide-docs[starts-with(my:fully-resolved-href(current()), guide/@original-dir)]"/>
            <xsl:if test="not($guide)">
              <xsl:message>BAD LINK FOUND! Unable to find referenced guide for this link: <xsl:value-of select="."/></xsl:message>
            </xsl:if>
            <xsl:attribute name="href" select="concat(my:guide-url($guide), '#', my:anchor-id-from-href(.,$guide))"/>
          </xsl:template>

                  <xsl:function name="my:guide-url">
                    <xsl:param name="guide" as="document-node()?"/> <!-- if absent, then it's a bad link, and we'll get the warning above -->
                    <xsl:sequence select="$guide/ml:external-uri-for-string(raw:target-guide-uri(.))"/>
                  </xsl:function>

                          <xsl:function name="my:fully-resolved-href">
                            <xsl:param name="href" as="attribute(href)"/>
                            <xsl:sequence select="resolve-uri($href, $href/ancestor::XML/@original-file)"/>
                          </xsl:function>

                  <xsl:function name="my:anchor-id-from-href" as="xs:string">
                    <xsl:param name="href" as="attribute(href)"/>
                    <xsl:param name="guide" as="document-node()?"/>
                    <xsl:variable name="resolved-href" select="my:fully-resolved-href($href)"/>
                    <xsl:variable name="is-top-level-section-link" select="$resolved-href = $fully-resolved-top-level-heading-references"/>

                    <xsl:value-of>
                      <!-- The section name of the guide -->
                      <xsl:value-of select="my:basename-stem($href)"/>
                      <!-- Leave out the _12345 part if we're linking to a top-level section -->
                      <xsl:if test="not($is-top-level-section-link)">
                        <xsl:variable name="id" select="my:extract-id-from-href($href)"/>
                        <xsl:variable name="section" select="$guide/guide/XML[starts-with($resolved-href,@original-file)]"/>
                        <!-- Always rewrite to the last ID that appears, so we have a canonical one we can script against in the TOC (which also uses the last one present) -->
                        <xsl:variable name="canonical-fragment-id" select="$section//*[A/@ID=$id]/A[@ID][last()]/@ID"/>
                        <xsl:value-of select="concat('_', $canonical-fragment-id)"/>
                      </xsl:if>
                    </xsl:value-of>
                  </xsl:function>

                          <xsl:function name="my:extract-id-from-href">
                            <xsl:param name="href" as="xs:string"/>
                            <xsl:sequence select="substring-before(substring-after($href,'#id('),')')"/>
                          </xsl:function>

                          <xsl:variable name="fully-resolved-top-level-heading-references" as="xs:string*"
                                        select="$raw:guide-docs/guide/XML/Heading-1/A/@ID/concat(ancestor::XML/@original-file,'#id(',.,')')"/>


  <xsl:template match="Hyperlink">
    <xsl:apply-templates/>
  </xsl:template>


  <xsl:template mode="capture-sections" match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:apply-templates mode="capture-sections-content" select="."/>
    </xsl:copy>
  </xsl:template>

          <xsl:template mode="capture-sections-content" match="*">
            <xsl:apply-templates mode="capture-sections"/>
          </xsl:template>

          <xsl:template mode="capture-sections-content" match="XML">
            <xsl:call-template name="capture-sections"/>
          </xsl:template>

          <xsl:template name="capture-sections">
            <xsl:param name="current-level" select="1"/>
            <!-- Initially, group the children -->
            <xsl:param name="current-group" select="node()"/>
            <!-- Each heading starts a new group -->
            <xsl:variable name="current-heading" select="concat('Heading-', $current-level)"/>
            <xsl:for-each-group select="$current-group" group-starting-with="*[local-name(.) eq $current-heading]">
              <xsl:choose>
                <xsl:when test="local-name(.) eq $current-heading">
                  <div class="section">
                    <!-- Recursively capture sections -->
                    <xsl:call-template name="capture-sections">
                      <xsl:with-param name="current-level" select="$current-level + 1"/>
                      <xsl:with-param name="current-group" select="current-group()"/>
                    </xsl:call-template>
                  </div>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:copy-of select="current-group()"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each-group>
          </xsl:template>


  <xsl:template mode="capture-lists" match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:apply-templates mode="capture-lists-content" select="."/>
    </xsl:copy>
  </xsl:template>

          <xsl:template mode="capture-lists-content" match="*">
            <xsl:apply-templates mode="capture-lists"/>
          </xsl:template>

          <xsl:template mode="capture-lists-content" match="div | CELL">
            <xsl:for-each-group select="*" group-adjacent="my:is-in-list(.) and not(self::div or self::CELL)">
              <xsl:apply-templates mode="outer-list" select="."/>
            </xsl:for-each-group>
          </xsl:template>

                  <xsl:template mode="outer-list" match="Number1">
                    <ol>
                      <xsl:for-each-group select="current-group()" group-starting-with="Number | Number1">
                        <li>
                          <xsl:variable name="nested-bullets-captured" as="element()*">
                            <xsl:call-template name="capture-nested-bullets"/>
                          </xsl:variable>
                          <!-- ASSUMPTION: If there's a nested NumberA list, then it comprises the rest of this list item. -->
                          <xsl:for-each-group select="$nested-bullets-captured" group-starting-with="NumberA1">
                            <xsl:apply-templates mode="inner-numbered-list" select="."/>
                          </xsl:for-each-group>
                        </li>
                      </xsl:for-each-group>
                    </ol>
                  </xsl:template>

                          <xsl:template mode="inner-numbered-list" match="NumberA1">
                            <ol>
                              <xsl:for-each-group select="current-group()" group-starting-with="NumberA1 | NumberA">
                                <li>
                                  <xsl:apply-templates mode="capture-lists" select="current-group()"/>
                                </li>
                              </xsl:for-each-group>
                            </ol>
                          </xsl:template>

                  <xsl:template mode="outer-list" match="Body-bullet">
                    <ul>
                      <xsl:for-each-group select="current-group()" group-starting-with="Body-bullet">
                        <li>
                          <xsl:call-template name="capture-nested-bullets"/>
                        </li>
                      </xsl:for-each-group>
                    </ul>
                  </xsl:template>

                          <xsl:template name="capture-nested-bullets">
                            <xsl:for-each-group select="current-group()" group-adjacent="exists(self::Body-bullet-2)">
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

                  <!-- If not part of a list, just copy the group through -->
                  <xsl:template mode="outer-list
                                      inner-list
                                      inner-numbered-list" match="*">
                    <xsl:apply-templates mode="capture-lists" select="current-group()"/>
                  </xsl:template>


                  <xsl:variable name="list-element-names" select="'Body-bullet',
                                                                  'Body-bullet-2',
                                                                  'Body-indent',
                                                                  'Body-indent-blockquote',
                                                                  'Number1',
                                                                  'NumberA1'"/>

                  <xsl:function name="my:is-in-list" as="xs:boolean">
                    <xsl:param name="e" as="element()"/>
                    <xsl:variable name="is-a-list-element" select="local-name($e) = $list-element-names"/>
                    <xsl:variable name="is-in-numbered-list" select="not($e/self::EndList-root) and
                                                                     $e/preceding-sibling::*[self::Number1 or self::EndList-root][1]
                                                                                            [self::Number1]"/>
                    <xsl:sequence select="$is-a-list-element or $is-in-numbered-list"/>
                  </xsl:function>

</xsl:stylesheet>
