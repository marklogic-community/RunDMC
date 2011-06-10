<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:my="http://localhost"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs raw my">

  <xsl:import href="../view/page.xsl"/>

  <xdmp:import-module href="/apidoc/setup/raw-docs-access.xqy" namespace="http://marklogic.com/rundmc/raw-docs-access"/>

  <xsl:output indent="no"/>

  <!-- Only overridden when, for convenience, we invoke this stylesheet from the rendering code during development. -->
  <xsl:param name="output-uri" select="raw:target-guide-uri(.)"/>

  <xsl:template match="/">
    <!-- We're reading from a doc in one database and writing to a doc in a different database, using a similar URI -->
    <xsl:result-document href="{$output-uri}">
      <guide xmlns="">
        <title>
          <xsl:value-of select="/guide/title"/>
        </title>
        <xsl:apply-templates select="guide/node()"/>
      </guide>
    </xsl:result-document>
  </xsl:template>

  <!-- Don't need this attribute at this stage; only used to resolve URIs of images being copied over -->
  <xsl:template match="/guide/@original-dir"/>

  <xsl:template match="pagenum | TITLE"/>

  <xsl:template match="Code">
    <!-- Don't include any whitespace inside <pre> until XSLTBUG 13495 is fixed -->
    <pre><xsl:apply-templates/></pre>
  </xsl:template>

  <xsl:template match="title">
    <h1>
      <xsl:apply-templates/>
    </h1>
  </xsl:template>

  <xsl:template match="*[starts-with(local-name(.),'Heading-')]">
    <xsl:variable name="heading-level" select="1 + number(substring-after(local-name(.),'-'))"/>
    <xsl:element name="h{$heading-level}">
      <xsl:apply-templates mode="heading-content" select="."/>
    </xsl:element>
  </xsl:template>

          <!-- Insert top-level anchor based on the original file name (special case so no extraneous number ID is appended) -->
          <xsl:template mode="heading-content" match="Heading-1">
            <a id="{my:anchor-id-for-top-level-heading(.)}"/>
            <xsl:next-match/>
          </xsl:template>

          <xsl:template mode="heading-content" match="*">
            <xsl:apply-templates mode="#default"/>
          </xsl:template>

                  <xsl:function name="my:anchor-id-for-top-level-heading">
                    <xsl:param name="heading-1" as="element(Heading-1)"/>
                    <xsl:sequence select="my:basename-stem($heading-1/parent::XML/@original-file)"/>
                  </xsl:function>

                  <xsl:function name="my:basename-stem">
                    <xsl:param name="url"/>
                    <xsl:sequence select="substring-before(tokenize($url,'/')[last()],'.xml')"/>
                  </xsl:function>


  <xsl:template match="IMAGE">
    <img src="{@href}"/>
  </xsl:template>

  <xsl:template match="Body">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- TODO: update after up-conversion -->
  <xsl:template match="Body-bullet">
    <!--
    <ul>
    -->
      <li>
        <xsl:apply-templates/>
      </li>
    <!--
    </ul>
    -->
  </xsl:template>

  <xsl:template match="Emphasis">
    <em>
      <xsl:apply-templates/>
    </em>
  </xsl:template>

  <!-- TODO: identify significant line breaks, e.g., in code examples, and modify rule(s) accordingly -->
  <!-- Strip out line breaks -->
  <xsl:template match="text()[not(ancestor::Code)]">
    <xsl:value-of select="replace(.,'&#xA;','')"/>
  </xsl:template>

  <!-- Strip out isolated line breaks in Code elements -->
  <xsl:template match="Code/text()[not(normalize-space(.))]"/>

  <!-- Remove existing top-level anchors; we'll use filename-based ones instead. -->
  <xsl:template match="Heading-1/A"/><!-- | A[starts-with(@ID,'pgfId-')]"/>--> <!-- Retain the pfgId ones, they're not necessarily dispensable after all. -->

  <xsl:template match="A">
    <a>
      <xsl:apply-templates select="@ID | @href"/>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

          <xsl:template match="A/@ID">
            <xsl:attribute name="id" select="my:full-anchor-id(.)"/>
          </xsl:template>

                  <xsl:function name="my:full-anchor-id">
                    <xsl:param name="ID-att"/>
                    <xsl:sequence select="concat(my:anchor-id-for-top-level-heading($ID-att/ancestor::XML/Heading-1),'_',$ID-att)"/>
                  </xsl:function>


          <!-- Links within the same guide -->
          <xsl:template match="A/@href[contains(.,'#id(')]" priority="1">
            <xsl:attribute name="href" select="concat('#',my:anchor-id-from-href(.))"/>
          </xsl:template>

          <!-- Links to other guides -->
          <xsl:template match="A/@href[starts-with(.,'../')]" priority="2">
            <xsl:attribute name="href" select="concat(my:referenced-guide-url(.),'#',my:anchor-id-from-href(.))"/>
          </xsl:template>

                  <xsl:function name="my:referenced-guide-url">
                    <xsl:param name="href" as="attribute(href)"/>
                    <xsl:variable name="referenced-guide" select="$raw:guide-docs[starts-with(my:fully-resolved-href($href), guide/@original-dir)]"/>
                    <xsl:if test="not($referenced-guide)">
                      <xsl:message>BAD LINK FOUND! Unable to find referenced guide for this link: <xsl:value-of select="$href"/></xsl:message>
                    </xsl:if>
                    <xsl:sequence select="$referenced-guide/ml:external-uri-for-string(raw:target-guide-uri(.))"/>
                  </xsl:function>

                          <xsl:function name="my:fully-resolved-href">
                            <xsl:param name="href" as="attribute(href)"/>
                            <xsl:sequence select="resolve-uri($href, $href/ancestor::XML/@original-file)"/>
                          </xsl:function>

                  <xsl:function name="my:anchor-id-from-href" as="xs:string">
                    <xsl:param name="href" as="attribute(href)"/>
                    <xsl:variable name="exclude-id-suffix" select="my:fully-resolved-href($href) = $fully-resolved-top-level-heading-references"/>
                    <!-- Leave out the _12345 part if we're linking to a top-level section -->
                    <xsl:sequence select="concat(my:basename-stem($href),
                                                 if ($exclude-id-suffix) then () else concat('_',my:number-from-href($href)))"/>
                  </xsl:function>

                          <xsl:function name="my:number-from-href">
                            <xsl:param name="href" as="xs:string"/>
                            <xsl:sequence select="substring-before(substring-after($href,'#id('),')')"/>
                          </xsl:function>

                          <xsl:variable name="fully-resolved-top-level-heading-references" as="xs:string*"
                                        select="$raw:guide-docs/guide/XML/Heading-1/A/@ID/concat(ancestor::XML/@original-file,'#id(',.,')')"/>


  <xsl:template match="Hyperlink">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Section groupings -->
  <!-- TODO: Consider recursively use multiple passes instead, converting "Heading-1", "Heading-2",
             etc. into a standard element each time. Or... just leave this ugly, repetitive code here. -->
  <xsl:template match="XML">
    <div class="section">
      <xsl:apply-templates select="Heading-1"/> <!-- ASSUMPTION: just one of these per <XML> container -->
      <xsl:for-each-group select="node() except Heading-1" group-starting-with="Heading-2">
        <xsl:choose>
          <xsl:when test="self::Heading-2">
            <div class="section">
              <xsl:for-each-group select="current-group()" group-starting-with="Heading-3">
                <xsl:choose>
                  <xsl:when test="self::Heading-3">
                    <div class="section">
                      <xsl:for-each-group select="current-group()" group-starting-with="Heading-4">
                        <xsl:choose>
                          <xsl:when test="self::Heading-4">
                            <div class="section">
                              <xsl:for-each-group select="current-group()" group-starting-with="Heading-5">
                                <xsl:choose>
                                  <xsl:when test="self::Heading-5">
                                    <div class="section">
                                      <xsl:apply-templates select="current-group()"/>
                                    </div>
                                  </xsl:when>
                                  <xsl:otherwise>
                                    <xsl:apply-templates select="current-group()"/>
                                  </xsl:otherwise>
                                </xsl:choose>
                              </xsl:for-each-group>
                            </div>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:apply-templates select="current-group()"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:for-each-group>
                    </div>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="current-group()"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </div>
  </xsl:template>

</xsl:stylesheet>
