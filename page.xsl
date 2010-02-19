<!DOCTYPE xsl:stylesheet [
<!ENTITY  base-path "http://xqzone-new.marklogic.com">
<!ENTITY  xhtml     "http://www.w3.org/1999/xhtml">
<!ENTITY  mlns      "http://developer.marklogic.com/site/internal">
]>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns      ="&xhtml;"
  xmlns:xhtml="&xhtml;"
  xmlns:ml               ="&mlns;"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xpath-default-namespace="&mlns;"
  exclude-result-prefixes="ml"
  xml:base="&base-path;">

  <xsl:variable name="content"    select="/"/>
  <xsl:variable name="base-uri"   select="base-uri($content)"/>

  <xsl:variable name="template"   select="document('template.xhtml')"/>
  <xsl:variable name="navigation" select="document('navigation.xml')"/>

  <xsl:variable name="external-uri" select="ml:external-uri(base-uri(/))"/>

  <!-- The URI occurs in the hierarchy either explicitly or implicitly using a prefix.
       If exact URI is found, then use that; otherwise, look for the appropriate prefix. -->
  <xsl:variable name="page-in-navigation" select="($navigation//page    [@href eq $external-uri],
                                                   $navigation//wildcard[starts-with($external-uri, @prefix)]) [1]"/>

  <!-- Start by processing the template page -->
  <xsl:template match="/">
    <!-- XSLT BUG WORKAROUND (outputs nothing) -->
    <xsl:value-of select="substring-after($external-uri,$external-uri)"/>

    <xsl:apply-templates select="$template/*"/>
  </xsl:template>

          <!-- By default, copy everything unchanged -->
          <xsl:template match="@* | node()">
            <xsl:copy>
              <xsl:apply-templates select="@* | node()"/>
            </xsl:copy>
          </xsl:template>

  <!-- Process page content when we hit the <ml:page-content> element -->
  <xsl:template match="page-content">
    <!--
    $external-uri: <xsl:value-of select="$external-uri"/>
    -->
    <xsl:apply-templates mode="page-content" select="$content/*"/>
  </xsl:template>

          <xsl:template mode="page-content" match="page">
            <xsl:apply-templates/>
          </xsl:template>

          <xsl:template mode="page-content" match="news">
          </xsl:template>

          <xsl:template mode="page-content" match="event">
          </xsl:template>


  <xsl:template match="top-nav">
    <ul>
      <xsl:apply-templates mode="top-nav" select="$navigation/*/page"/>
    </ul>
  </xsl:template>

          <xsl:template mode="top-nav" match="page">
            <li>
              <xsl:apply-templates mode="current-page-att" select="."/>
              <a href="{@href}">
                <xsl:value-of select="@display"/>
              </a>
            </li>
          </xsl:template>

                  <xsl:template mode="current-page-att" match="page"/>

                  <xsl:template mode="current-page-att" match="page[@href eq $external-uri]">
                    <xsl:attribute name="class">current</xsl:attribute>
                  </xsl:template>


  <xsl:template match="breadcrumbs">
    <xsl:apply-templates mode="breadcrumbs" select="$page-in-navigation"/>
  </xsl:template>

          <!-- No breadcrumbs on home page -->
          <xsl:template mode="breadcrumbs" match="page[@href eq '/']"/>

          <!-- But do display them on every other page -->
          <xsl:template mode="breadcrumbs" match="page | wildcard">
            <div class="breadcrumb">
              <a href="/">Developer Community</a>
              <xsl:apply-templates mode="breadcrumb-link" select="ancestor::page"/>
              <xsl:text> > </xsl:text>
              <xsl:apply-templates mode="breadcrumb-display" select="."/>
            </div>
          </xsl:template>

                  <xsl:template mode="breadcrumb-display" match="page">
                    <xsl:value-of select="@display"/>
                  </xsl:template>

                  <xsl:template mode="breadcrumb-display" match="wildcard">
                    <xsl:value-of select="$content/*/title"/>
                  </xsl:template>


                  <xsl:template mode="breadcrumb-link" match="page">
                    <xsl:text> > </xsl:text>
                    <a href="{@href}">
                      <xsl:value-of select="@display"/>
                    </a>
                  </xsl:template>


  <!-- The <body> CSS class varies from page to page -->
  <xsl:template match="@ml:class">
    <xsl:attribute name="class">
      <xsl:apply-templates mode="body-class"        select="$page-in-navigation"/>
      <xsl:apply-templates mode="body-class-extra"  select="$content/page/@css-class"/>
    </xsl:attribute>
  </xsl:template>

          <xsl:template mode="body-class" match="page"     >main_page</xsl:template>
          <xsl:template mode="body-class" match="page//page">sub_page</xsl:template>

          <xsl:template mode="body-class-extra" match="@css-class">
            <xsl:text> </xsl:text>
            <xsl:value-of select="."/>
          </xsl:template>


  <xsl:template match="tabbed-features">
    <div id="special_intro">
      <ul class="nav">
        <xsl:apply-templates mode="feature-tab" select="feature"/>
      </ul>
      <xsl:apply-templates mode="feature-tab-content" select="feature"/>
    </div>
  </xsl:template>

          <xsl:template mode="feature-tab" match="feature">
            <li>
              <a href="#section{position()}">
                <xsl:value-of select="document(@href)/feature/title"/>
              </a>
            </li>
          </xsl:template>

          <xsl:template mode="feature-tab-content" match="feature">
            <xsl:variable name="feature" select="document(@href)/feature"/>

            <div class="section" id="section{position()}">
              <xsl:apply-templates mode="feature-content" select="$feature/image,
                                                                  $feature/main-points,
                                                                  $feature/read-more"/>
            </div>
          </xsl:template>

                  <xsl:template mode="feature-content" match="image">
                    <div class="align_right">
                      <img src="{@src}" alt="{@alt}"/>
                      <xsl:apply-templates mode="feature-content" select="caption"/>
                    </div>
                  </xsl:template>

                          <xsl:template mode="feature-content" match="caption">
                            <div class="caption">
                              <xsl:apply-templates/>
                            </div>
                          </xsl:template>

                  <xsl:template mode="feature-content" match="main-points">
                    <ul>
                      <xsl:apply-templates mode="feature-content" select="point"/>
                    </ul>
                  </xsl:template>

                          <xsl:template mode="feature-content" match="point">
                            <li>
                              <xsl:apply-templates/>
                            </li>
                          </xsl:template>

                  <xsl:template mode="feature-content" match="read-more">
                    <ul class="more">
                      <xsl:apply-templates mode="feature-content" select="link"/>
                    </ul>
                  </xsl:template>

                          <xsl:template mode="feature-content" match="link">
                            <li>
                              <a href="{@href}">
                                <xsl:apply-templates/>
                                <xsl:text>&#160;></xsl:text>
                              </a>
                            </li>
                          </xsl:template>


  <xsl:template match="announcement">
    <div class="announcement single">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="recent-news-and-events">
    <xsl:variable name="news-doc" select="ml:latest-news-doc()"/>
    <xsl:variable name="event-doc" select="ml:latest-event-doc()"/>
    <div class="double">
      <div>
        <h2>Recent News</h2>
        <xsl:apply-templates mode="news-excerpt" select="$news-doc">
          <xsl:with-param name="suppress-more-link" select="string(@suppress-more-links) eq 'yes'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
      <div>
        <h2>Upcoming Events</h2>
        <xsl:apply-templates mode="event-excerpt" select="$event-doc">
          <xsl:with-param name="suppress-more-link" select="string(@suppress-more-links) eq 'yes'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
    </div>
  </xsl:template>

          <xsl:template mode="news-excerpt" match="news">
            <h3>
              <xsl:apply-templates select="title/node()"/>
            </h3>
            <p>
              <xsl:apply-templates select="if (normalize-space(abstract)) then abstract/node()
                                                                          else body/xhtml:p[1]/node()"/>
            </p>
            <a class="more" href="{ml:external-uri(base-uri(.))}">Read more&#160;></a>
            <xsl:apply-templates mode="more-link" select="."/>
          </xsl:template>

          <xsl:template mode="event-excerpt" match="event">
            <h3>
              <xsl:apply-templates select="title/node()"/>
            </h3>
            <!-- TODO: Possibly update this once I see some example events -->
            <xsl:apply-templates select="description/node()"/>
            <dl>
              <xsl:apply-templates mode="event-details" select="details/*"/>
            </dl>
            <a class="more" href="{ml:external-uri(base-uri(.))}">More information&#160;></a>
            <xsl:apply-templates mode="more-link" select="."/>
          </xsl:template>

                  <xsl:template mode="more-link" match="*">
                    <xsl:param name="suppress-more-link"
                               tunnel="yes"
                               as="xs:boolean"
                               select="false()"/>
                    <xsl:if test="not($suppress-more-link)">
                      <xsl:variable name="href">
                        <xsl:apply-templates mode="more-link-href" select="."/>
                      </xsl:variable>
                      <xsl:variable name="link-text">
                        <xsl:apply-templates mode="more-link-text" select="."/>
                      </xsl:variable>

                      <div class="more">
                        <a href="{$href}">
                          <xsl:value-of select="$link-text"/>
                          <xsl:text>&#160;></xsl:text>
                        </a>
                      </div>

                    </xsl:if>
                  </xsl:template>

                          <xsl:template mode="more-link-href" match="event">/events</xsl:template>
                          <xsl:template mode="more-link-href" match="news" >/news</xsl:template>

                          <xsl:template mode="more-link-text" match="news" >More News</xsl:template>
                          <xsl:template mode="more-link-text" match="event">More Events</xsl:template>


                  <!-- TODO: For dates and times, consider use ISO 8601 format (in the source data) instead -->
                  <xsl:template mode="event-details" match="*">
                    <dt>
                      <xsl:apply-templates mode="event-detail-name" select="."/>
                      <xsl:text>:</xsl:text>
                    </dt>
                    <dd>
                      <xsl:apply-templates/>
                    </dd>
                  </xsl:template>

                          <xsl:template mode="event-detail-name" match="date"     >Date</xsl:template>
                          <xsl:template mode="event-detail-name" match="time"     >Time</xsl:template>
                          <xsl:template mode="event-detail-name" match="location" >Location</xsl:template>
                          <xsl:template mode="event-detail-name" match="topic"    >Topic</xsl:template>
                          <xsl:template mode="event-detail-name" match="presenter">Presenter</xsl:template>

              <!--
              <h3>Denver Mark Logic User Group (DenMARK)</h3>
              <p>The first instance of the Mark Logic user group in Denver will take place on October 12, 2009 at 7pm.  The main speaker will be Clark Richey, Mark Logic Community Champion who will talk about MarkLogic Application Services.</p>
              <dl>
                <dt>Date:</dt>
                <dd>2009-10-12</dd>
                <dt>Time:</dt>
                <dd>7pm</dd>
                <dt>Location:</dt>
                <dd>Auraria Campus</dd>
                <dt>Topic:</dt>
                <dd>MarkLogic Application Services</dd>
                <dt>Presenter:</dt>
                <dd>Clark Richey</dd>
              </dl>
              <a class="more" href="">More information&#160;&gt;</a>
              <div class="more"><a href="">More Events&#160;&gt;</a></div>
              -->

  <xsl:function name="ml:latest-news-doc">
    <!-- TODO: implement this -->
    <xsl:sequence select="document('/news/1234.xml')"/>
  </xsl:function>

  <xsl:function name="ml:latest-event-doc">
    <!-- TODO: implement this -->
    <xsl:sequence select="document('/events/1234.xml')"/>
  </xsl:function>

  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="internal-uri" as="xs:string"/>
    <xsl:variable name="doc-path"   select="substring-after($internal-uri, '&base-path;')"/>
    <xsl:sequence select="if ($doc-path eq '/index.xml') then '/' else substring-before($doc-path, '.xml')"/>
  </xsl:function>

</xsl:stylesheet>
