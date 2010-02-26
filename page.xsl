<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:output doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
              omit-xml-declaration="yes"/>

  <xsl:variable name="content"    select="/"/>
  <xsl:variable name="base-uri"   select="base-uri($content)"/>

  <xsl:variable name="template"   select="document('/private/config/template.xhtml')"/>
  <xsl:variable name="navigation" select="document('/private/config/navigation.xml')"/>

  <xsl:variable name="external-uri" select="ml:external-uri(base-uri(/))"/>

  <!-- The page occurs in the hierarchy either explicitly or as encompassed by a wildcard.

       If the exact URI is found, then use that;
       otherwise, look to see if the current page falls under a content-type wildcard.
  -->
  <xsl:variable name="page-in-navigation" select="($navigation//page         [@href eq $external-uri],
                                                   $navigation//documents    [$content/document/@type eq @type],
                                                   $navigation//announcements[$content/announcement],
                                                   $navigation//events       [$content/event]
                                                  )
                                                  [1]"/>

  <!-- Start by processing the template page -->
  <xsl:template match="/">
    <!-- XSLT BUG WORKAROUND (outputs nothing); works because it apparently forces evaluation earlier -->
    <xsl:value-of select="$content/.."/> <!-- empty sequence -->
    <xsl:value-of select="substring-after($external-uri,$external-uri)"/> <!-- empty string -->

    <xsl:apply-templates select="$template/*"/>
  </xsl:template>

          <!-- By default, copy everything unchanged -->
          <xsl:template match="@* | comment() | text() | processing-instruction()">
            <xsl:copy/>
          </xsl:template>

          <!-- For elements, "replicate" rather than copy, to prevent unwanted namespace nodes in output -->
          <xsl:template match="*">
            <xsl:element name="{name()}" namespace="{namespace-uri()}">
              <xsl:apply-templates select="@* | node()"/>
            </xsl:element>
          </xsl:template>


  <!-- Process page content when we hit the <ml:page-content> element -->
  <xsl:template match="page-content">
    <xsl:apply-templates mode="page-content" select="$content/*"/>
  </xsl:template>

          <xsl:template mode="page-content" match="page">
            <xsl:apply-templates/>
          </xsl:template>

          <!--
          <xsl:template mode="page-content" match="announcement">
          </xsl:template>

          <xsl:template mode="page-content" match="event">
          </xsl:template>
          -->

          <xsl:template mode="page-content" match="document">
            <!-- TODO: What's the intention of this form? The whole document is on the client, but it has no client-side behavior
            <form id="doc_search" action="" method="get">

              <fieldset>
                <legend><label for="ds_inp">Search current document</label></legend>
                <input id="ds_inp" type="text" />
                <input type="submit" />
              </fieldset>
            </form>
            -->
            <!-- placeholder for form to get CSS to display background -->
            <div id="doc_search"/>

            <h2>
              <xsl:apply-templates select="title/node()"/>
            </h2>
            <div class="author">
              <xsl:apply-templates select="author/node()"/>
            </div>
            <div class="date"> 
              <xsl:text>Last updated </xsl:text>
              <xsl:value-of select="last-updated"/>
            </div>
            <xsl:apply-templates select="body/node()"/>
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

                  <xsl:template mode="current-page-att" match="page[descendant-or-self::* intersect $page-in-navigation]">
                    <xsl:attribute name="class">current</xsl:attribute>
                  </xsl:template>


  <xsl:template match="doc-breadcrumbs"/>
  <!-- Only display this for Learn docs -->
  <xsl:template match="doc-breadcrumbs[$content/document]">
    <div id="content_title">
      <xsl:call-template name="breadcrumbs"/>
    </div>
  </xsl:template>

  <!-- For Learn content, breadcrumbs are handled elsewhere -->
  <xsl:template match="breadcrumbs[$content/document]"/>

  <xsl:template match="breadcrumbs" name="breadcrumbs">
    <xsl:apply-templates mode="breadcrumbs" select="$page-in-navigation"/>
  </xsl:template>

          <!-- No breadcrumbs on home page -->
          <xsl:template mode="breadcrumbs" match="page[@href eq '/']"/>

          <!-- But do display them on every other page -->
          <xsl:template mode="breadcrumbs" match="*">
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

                  <xsl:template mode="breadcrumb-display" match="*">
                    <xsl:value-of select="$content/*/title"/>
                  </xsl:template>


                  <xsl:template mode="breadcrumb-link" match="page">
                    <xsl:text> > </xsl:text>
                    <a href="{@href}">
                      <xsl:value-of select="@display"/>
                    </a>
                  </xsl:template>

  <xsl:template match="sub-nav[$content/document]">
    <h2>Document TOC</h2>
    <!-- TODO: implement doc TOC -->
  </xsl:template>

  <xsl:template match="sub-nav">
    <div class="subnav">
      <xsl:apply-templates mode="sub-nav" select="$page-in-navigation/ancestor-or-self::page[group]/group"/>
    </div>
  </xsl:template>

          <xsl:template mode="sub-nav" match="group">
            <h2>
              <xsl:value-of select="@display"/>
            </h2>
            <ul>
              <xsl:apply-templates mode="sub-nav" select="page | group"/>
            </ul>
          </xsl:template>

                  <xsl:template mode="sub-nav" match="group/group">
                    <li>
                      <span>
                        <xsl:value-of select="@display"/>
                      </span>
                      <ul>
                        <xsl:apply-templates mode="sub-nav" select="page"/>
                      </ul>
                    </li>
                  </xsl:template>


                  <!-- TODO: Find out whether nested lists should be supported. The JavaScript appears to be broken currently. -->
                  <xsl:template mode="sub-nav" match="page">
                    <li>
                      <xsl:apply-templates mode="sub-nav-current-att" select="."/>
                      <a href="{@href}">
                        <xsl:value-of select="@display"/>
                      </a>
                    </li>
                  </xsl:template>

                          <xsl:template mode="sub-nav-current-att" match="page"/>
                          <xsl:template mode="sub-nav-current-att" match="page[. intersect $page-in-navigation/ancestor-or-self::*]">
                            <xsl:attribute name="class">current</xsl:attribute>
                          </xsl:template>


  <!-- The <body> CSS class varies from page to page -->
  <xsl:template match="@ml:class">
    <xsl:attribute name="class">
      <xsl:apply-templates mode="body-class"        select="$page-in-navigation"/>
      <xsl:apply-templates mode="body-class-extra"  select="$page-in-navigation"/>
    </xsl:attribute>
  </xsl:template>

          <xsl:template mode="body-class" match="navigation/page">main_page</xsl:template>
          <xsl:template mode="body-class" match="*"              >sub_page</xsl:template>

          <xsl:template mode="body-class-extra" match="*"/>
          <xsl:template mode="body-class-extra" match="page[@href eq '/']                                  "> home</xsl:template>
          <xsl:template mode="body-class-extra" match="documents                                           "> layout2</xsl:template>
          <xsl:template mode="body-class-extra" match="page[ancestor-or-self::page/@narrow-sidebar = 'yes']"> layout3</xsl:template>

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
    <xsl:variable name="announcement" select="ml:latest-announcement()"/>
    <xsl:variable name="event"        select="ml:latest-event()"/>
    <div class="double">
      <div>
        <h2>Recent News</h2>
        <xsl:apply-templates mode="news-excerpt" select="$announcement">
          <xsl:with-param name="suppress-more-link" select="string(@suppress-more-links) eq 'yes'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
      <div>
        <h2>Upcoming Events</h2>
        <xsl:apply-templates mode="event-excerpt" select="$event">
          <xsl:with-param name="suppress-more-link" select="string(@suppress-more-links) eq 'yes'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
    </div>
  </xsl:template>

          <xsl:template mode="news-excerpt" match="announcement">
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

                          <xsl:template mode="more-link-href" match="event"       >/events</xsl:template>
                          <xsl:template mode="more-link-href" match="announcement">/news</xsl:template>

                          <xsl:template mode="more-link-text" match="event"       >More Events</xsl:template>
                          <xsl:template mode="more-link-text" match="announcement">More News</xsl:template>


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

  <xsl:template match="recent-tutorial">
    <xsl:apply-templates mode="recent-tutorial" select="ml:latest-tutorial()/*"/>
  </xsl:template>

          <xsl:template mode="recent-tutorial" match="*">
            <div class="single">
              <h2>Learn This!</h2>
              <h3>
                <xsl:apply-templates select="title/node()"/>
              </h3>
              <div class="author">
                <xsl:text>By </xsl:text>
                <xsl:value-of select="author"/>
              </div>
              <p>
                <xsl:apply-templates select="if (normalize-space(abstract)) then abstract/node()
                                                                            else body/xhtml:p[1]/node()"/>
                <xsl:text> </xsl:text>
                <a class="more" href="{ml:external-uri(base-uri(.))}">Read&#160;more&#160;></a>
              </p>
            </div>
          </xsl:template>


  <xsl:template match="read-more">
    <a class="more" href="{@href}">Read&#160;more&#160;></a>
  </xsl:template>


  <xsl:template match="document-list">
    <xsl:variable name="docs" select="ml:lookup-docs(string(@type), string(@topic))"/>
    <div class="doclist">
      <h2>Documents</h2>
      <!-- 2.0 feature TODO: add pagination -->
      <span class="amount">
        <xsl:value-of select="count($docs)"/>
        <xsl:text> of </xsl:text>
        <xsl:value-of select="count($docs)"/>
        <xsl:text> documents</xsl:text>
      </span>
      <!--
      <form action="" method="get">
        <div>
          <label for="kw_inp">Search documents by keyword</label>
          <input id="kw_inp" type="text"/>
          <input type="submit"/>
        </div>
      </form>
      -->
      <table>
        <colgroup>
          <col class="col1"/>
          <col class="col2"/>
          <col class="col3"/>
          <col class="col4"/>
        </colgroup>
        <thead>
          <tr>
            <th scope="col">Title</th>
            <th scope="col">Document&#160;Type</th>
            <th scope="col">Topic(s)</th>
            <th scope="col" class="sort">Date</th>
          </tr>
        </thead>
        <tbody>
          <xsl:apply-templates mode="doc-listing" select="$docs">
            <xsl:sort select="created" order="descending"/>
          </xsl:apply-templates>
        </tbody>
      </table>
    </div>
  </xsl:template>

          <xsl:template mode="doc-listing" match="document">
            <tr>
              <xsl:if test="position() mod 2 eq 0">
                <xsl:attribute name="class">alt</xsl:attribute>
              </xsl:if>
              <th>
                <a href="{ml:external-uri(base-uri())}">
                  <xsl:value-of select="title"/>
                </a>
              </th>
              <td>
                <xsl:value-of select="replace(@type,' ','&#160;')"/>
              </td>
              <td>
                <xsl:value-of select="topics/topic/replace(.,' ','&#160;')" separator=", "/>
              </td>
              <td>
                <xsl:value-of select="created"/>
              </td>
            </tr>
          </xsl:template>


  <xsl:function name="ml:latest-announcement">
    <!-- TODO: implement this -->
    <xsl:sequence select="document('/news/1234.xml')"/>
  </xsl:function>

  <xsl:function name="ml:latest-event">
    <!-- TODO: implement this -->
    <xsl:sequence select="document('/events/1234.xml')"/>
  </xsl:function>

  <xsl:function name="ml:latest-tutorial">
    <!-- TODO: implement this -->
    <xsl:sequence select="document('/learn/intro.xml')"/>
  </xsl:function>

  <xsl:function name="ml:lookup-docs" as="element()*">
    <xsl:param name="type"  as="xs:string"/>
    <xsl:param name="topic" as="xs:string"/>
    <xsl:sequence select="collection()/document[(($type  eq @type)        or not($type)) and
                                                (($topic =  topics/topic) or not($topic))]"/>
  </xsl:function>


  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:sequence select="if ($doc-path eq '/index.xml') then '/' else substring-before($doc-path, '.xml')"/>
  </xsl:function>

</xsl:stylesheet>
