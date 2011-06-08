<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
  xmlns="http://www.w3.org/1999/xhtml"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs raw">

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
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

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

  <xsl:template match="A">
    <a>
      <xsl:apply-templates select="@ID | @href"/>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

          <xsl:template match="A/@ID">
            <xsl:attribute name="id" select="concat('ID_',.)"/>
          </xsl:template>

          <xsl:template match="A/@href[contains(.,'#id(')]">
            <xsl:attribute name="href" select="concat('#ID_',substring-before(substring-after(.,'#id('),')'))"/>
          </xsl:template>

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
