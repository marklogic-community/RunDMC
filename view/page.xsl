<!-- The main, top-level stylesheet that's invoked for rendering
     every page of the site. Called directly by the controller scripts
     (transform.xqy).
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:qp   ="http://www.marklogic.com/ps/lib/queryparams"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="qp xs ml xdmp">

  <xsl:include href="navigation.xsl"/>
  <xsl:include href="widgets.xsl"/>
  <xsl:include href="comments.xsl"/>
  <xsl:include href="tag-library.xsl"/>
  <xsl:include href="search.xsl"/>
  <xsl:include href="xquery-imports.xsl"/>

  <!-- See http://www.w3.org/TR/html5/syntax.html#the-doctype and http://www.w3.org/html/wg/tracker/issues/54 -->
  <xsl:output doctype-system="about:legacy-compat"
              omit-xml-declaration="yes"/>

  <xsl:param name="params" as="element()*"/>
  <xsl:param name="error" as="xs:string*"/>
  <xsl:param name="errorMessage" as="xs:string*"/>
  <xsl:param name="errorDetail" as="xs:string*"/>

  <xsl:variable name="DEBUG" select="false()"/>

  <xsl:variable name="original-content" select="/"/>

  <xsl:variable name="highlight-search" select="string($params[@name eq 'hl'])"/>
  <xsl:variable name="content" select="if ($highlight-search) then $highlighted-content else /"/>

          <xsl:variable name="highlighted-content">
            <xsl:apply-templates mode="preserve-base-uri" select="u:highlight-doc(/, $highlight-search)"/>
          </xsl:variable>

                  <xsl:template mode="preserve-base-uri" match="@* | node()">
                    <xsl:copy>
                      <xsl:apply-templates mode="#current" select="@* | node()"/>
                    </xsl:copy>
                  </xsl:template>

                  <!-- Add an xml:base attribute to the document element so the base URI is preserved, even in the highlighted document -->
                  <xsl:template mode="preserve-base-uri" match="/*">
                    <xsl:copy>
                      <xsl:attribute name="xml:base" select="base-uri($original-content)"/>
                      <xsl:apply-templates mode="#current" select="@* | node()"/>
                    </xsl:copy>
                  </xsl:template>


  <xsl:variable name="template-dir" select="'/config'"/>

  <xsl:variable name="optimized-template-file" select="concat($template-dir,'/template.optimized.xhtml')"/>
  <xsl:variable   name="regular-template-file" select="concat($template-dir,'/template.xhtml')"/>

  <xsl:variable name="template" select="if (xdmp:uri-is-file($optimized-template-file))
                                              then u:get-doc($optimized-template-file) 
                                              else u:get-doc(  $regular-template-file)"/>

  <xsl:variable name="preview-context" select="$params[@name eq 'preview-as-if-at']"/>

  <xsl:variable name="external-uri" select="if (normalize-space($preview-context)) then $preview-context
                                                                                   else ml:external-uri(/)"/>

  <xsl:variable name="site-title" select="'MarkLogic Developer Community'"/>


  <!-- WORKAROUND for XSLTBUG 12857. These variable definitions really belong in navigation.xsl;
       they're only included here as a workaround. -->

        <!-- For performance reasons, we no longer pre-process the navigation config on every request;
             it is now an, er, PRE-process. -->
        <xsl:variable name="navigation" select="if ($navigation-cached) then $navigation-cached
                                                                        else ($populated-navigation,
                                                                              ml:save-cached-navigation($populated-navigation))"/>

                <xsl:variable name="navigation-cached" select="ml:get-cached-navigation()"/>

                <xsl:variable name="populated-navigation">
                  <xsl:apply-templates mode="pre-process-navigation" select="$ml:raw-navigation"/>
                </xsl:variable>
  <!-- END WORKAROUND -->


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

          <!-- Strip out inline custom tags (such as <ml:teaser>) -->
          <xsl:template match="ml:*">
            <xsl:apply-templates/>
          </xsl:template>

          <!-- For elements, "replicate" rather than copy, to prevent unwanted namespace nodes in output -->
          <xsl:template match="*">
            <xsl:element name="{name()}" namespace="{namespace-uri()}">
              <xsl:apply-templates select="@* | node()"/>
            </xsl:element>
          </xsl:template>


  <!-- Bump up the heading number (i.e. increase the depth) of headings in paginated lists (of blog posts) -->
  <xsl:template match="xhtml:h3
                     | xhtml:h4
                     | xhtml:h5
                     | xhtml:h6
                     | xhtml:h7
                     | xhtml:h8">
    <xsl:param name="in-paginated-list" select="false()" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$in-paginated-list">
        <xsl:element name="h{1 + number(substring-after(local-name(.),'h'))}" namespace="{namespace-uri()}">
          <xsl:apply-templates select="@* | node()"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- What to put in the <title> tag -->
  <xsl:template match="page-title">
    <!-- strip out any inline markup, e.g., <sup> tags -->
    <xsl:value-of>
      <xsl:apply-templates mode="page-title" select="$content/*"/>
    </xsl:value-of>
  </xsl:template>

          <xsl:template mode="page-title" match="page[$external-uri eq '/']">
            <xsl:value-of select="$site-title"/>
          </xsl:template>

          <xsl:template mode="page-title" match="*">
            <xsl:apply-templates mode="page-specific-title" select="."/>
            <xsl:text> &#8212; </xsl:text>
            <xsl:value-of select="$site-title"/>
          </xsl:template>      

                  <xsl:template mode="page-specific-title" match="page">
                    <xsl:apply-templates select="( xhtml:h1
                                                 | xhtml:div/xhtml:h1
                                                 | xhtml:h2
                                                 | xhtml:div/xhtml:h2
                                                 )[1]
                                                 /node()"/>
                  </xsl:template>

                  <!-- TODO: We should stop using <page> for product pages. It should change to <Product> -->
                  <xsl:template mode="page-specific-title" match="page[product-info/@name]">
                    <xsl:value-of select="product-info/@name"/>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="page[product-info/name]">
                    <xsl:apply-templates select="product-info/name"/>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="page[ml:external-uri(.) eq '/search']">Search Results</xsl:template>

                  <xsl:template mode="page-specific-title" match="Project">
                    <xsl:apply-templates select="name/node()"/>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="Announcement | Event | Article | Post">
                    <xsl:value-of select="title"/>
                  </xsl:template>

  <!-- Handle errors -->
  <xsl:template match="errors">
     <h2>
         <xsl:value-of select="$error"/>
         <xsl:text> &#8212; </xsl:text>
         <xsl:value-of select="$errorMessage"/>
     </h2>
     <pre>
        <xsl:value-of select="$errorDetail"/>
     </pre>
  </xsl:template>

  <!-- Pre-populate the search box, if applicable -->
  <xsl:template match="xhtml:input[@name eq 'q']/@ml:value">
    <xsl:attribute name="value">
      <xsl:value-of select="$params[@name eq 'q']"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="comment-section">
    <xsl:apply-templates mode="comment-section" select="$content/*"/>
  </xsl:template>

  <xsl:template match="page-heading">
    <h2>
      <xsl:apply-templates mode="page-specific-title" select="$content/*"/>
      <xsl:apply-templates mode="page-heading-suffix" select="$content/*"/>
    </h2>
  </xsl:template>

          <xsl:template mode="page-heading-suffix" match="*"/>
          <!-- Append Atom feed link to Blog page heading -->
          <xsl:template mode="page-heading-suffix" match="page[$external-uri eq '/blog']">
            <a href="/blog/atom.xml?feed=blog">
              <img src="/images/i_rss.png" alt="(RSS)" width="24" height="23"/>
            </a>
          </xsl:template>

  <!-- Conditional template support: process the first child that matches -->
  <xsl:template match="choose">
    <xsl:apply-templates select="*[@href eq $external-uri or not(@href)][1]/node()"/>
  </xsl:template>

  <!-- Process page content when we hit the <ml:page-content> element -->
  <xsl:template match="page-content" name="page-content">
    <xsl:if test="$DEBUG">
      <xsl:copy-of select="$params"/>
    </xsl:if>
    <xsl:apply-templates mode="page-content"    select="$content/*"/>
  </xsl:template>

          <xsl:template mode="page-content" match="page">
            <xsl:apply-templates select="node() except (xhtml:h1, xhtml:h2)"/>
          </xsl:template>


          <xsl:template mode="page-content" match="Post | Announcement | Event">
            <xsl:apply-templates mode="blog-post" select="."/>
          </xsl:template>

                  <xsl:template mode="blog-post paginated-list-item" match="Post | Announcement | Event">

                    <!-- Overridden when grouped with other posts in the same page (mode="paginated-list-item") -->
                    <xsl:param name="in-paginated-list" select="false()" tunnel="yes"/>

                    <article class="post">
                      <header>
                        <h3>
                          <!-- If we're just displaying one post on this page, then hide this (repeated) post title -->
                          <xsl:if test="not($in-paginated-list)">
                            <xsl:attribute name="style">display: none</xsl:attribute>
                          </xsl:if>
                          <a href="{ml:external-uri(.)}">
                            <xsl:apply-templates select="title/node()"/>
                          </a>
                        </h3>
                        <div class="date_author">
                          <xsl:apply-templates mode="post-date" select="."/>
                          <xsl:text> </xsl:text>
                          <!-- Only display the byline if an author is present -->
                          <xsl:apply-templates mode="post-author" select="author[1]"/>
                        </div>

                        <!-- Display the comment count widget only if we're on a list of more than one post;
                             disabled when we're just displaying one blog post, because the comment count
                             automatically appears above the comment submit form section. Suppressing it here
                             ensures we don't display it twice. -->
                        <xsl:if test="$in-paginated-list">
                          <xsl:apply-templates mode="comment-count" select="."/>
                        </xsl:if>
                      </header>

                      <div class="body">
                        <xsl:apply-templates mode="post-content" select="."/>
                      </div>

                    </article>
                  </xsl:template>

                          <!-- Don't display the "created" date on event pages -->
                          <xsl:template mode="post-date" match="Event"/>
                          <xsl:template mode="post-date" match="Post | Announcement">
                            <time pubdate="true" datetime="{created}">
                              <xsl:value-of select="ml:display-date(created)"/>
                            </time>
                          </xsl:template>

                          <xsl:template mode="post-author" match="author">
                            <xsl:text>by </xsl:text>
                            <span class="author">
                              <xsl:apply-templates mode="author-listing" select="../author"/>
                            </span>
                          </xsl:template>

                          <xsl:template mode="post-content" match="Post | Announcement">
                            <xsl:apply-templates select="body/node()"/>
                          </xsl:template>

                          <xsl:template mode="post-content" match="Event">
                            <div class="info">
                              <table>
                                <xsl:apply-templates mode="event-details" select="details/*"/>
                              </table>
                            </div>
                            <xsl:apply-templates select="description/node()"/>
                          </xsl:template>


          <xsl:template mode="page-content" match="Article">
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
              <xsl:apply-templates mode="author-listing" select="author"/>
            </div>
            <div class="date"> 
              <xsl:text>Last updated </xsl:text>
              <xsl:value-of select="last-updated"/>
            </div>
            <br/>
            <xsl:apply-templates select="body/node()">
              <xsl:with-param name="annotate-headings" select="true()" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:template>

                  <xsl:template mode="author-listing" match="author[1]" priority="1">
                    <xsl:apply-templates/>
                  </xsl:template>

                  <xsl:template mode="author-listing" match="author">
                    <xsl:text>, </xsl:text>
                    <xsl:apply-templates/>
                  </xsl:template>

                  <xsl:template mode="author-listing" match="author[last()]">
                    <xsl:text> and </xsl:text>
                    <xsl:apply-templates/>
                  </xsl:template>


          <xsl:template mode="page-content" match="Project">
            <h1>Code</h1>
            <h2>
              <xsl:value-of select="name"/>
            </h2>
            <xsl:apply-templates select="description/node()"/>
            <xsl:if test="versions/@get-involved-href">
            <div class="action repo">
              <a href="{versions/@get-involved-href}">
                Browse <xsl:value-of select="versions/@repo"/> repository
              </a>
            </div>
            </xsl:if>

            <xsl:if test="versions/version/@href">
            <table class="table4">
              <thead>
                <tr>
                  <th scope="col">
                    Download
                  </th>
                  <th class="size" scope="col">MarkLogic Version Needed</th>
                  <!--
                  <th class="last" scope="col">Date Posted</th>
                  -->
                </tr>
              </thead>
              <tbody>
                <xsl:apply-templates mode="project-version" select="versions/version"/>
              </tbody>
            </table>
            </xsl:if>
            <!--
            <div class="action">
              <a href="{contributors/@href}">Contributors</a>
            </div>
            -->
            <xsl:apply-templates select="top-threads"/>
          </xsl:template>

                  <xsl:template mode="project-version" match="version">
                    <tr>
                      <xsl:if test="position() mod 2 eq 1">
                        <xsl:attribute name="class">alt</xsl:attribute>
                      </xsl:if>
                      <td>
                        <a href="{@href}">
                          <xsl:value-of select="ml:file-from-path(@href)"/>
                        </a>
                      </td>
                      <td>
                        <xsl:if test="normalize-space(@server-version)">
                            <xsl:text>MarkLogic Server </xsl:text>
                            <xsl:value-of select="@server-version"/>
                            <xsl:text> or later</xsl:text>
                        </xsl:if>
                      </td>
                      <!--
                      <td>
                        <xsl:value-of select="@date"/>
                      </td>
                      -->
                    </tr>
                  </xsl:template>

                          <xsl:function name="ml:file-from-path" as="xs:string">
                            <xsl:param name="path" as="xs:string"/>
                            <xsl:sequence select="if (contains($path, '/')) then ml:file-from-path(substring-after($path, '/'))
                                                                            else $path"/>
                          </xsl:function>


  <xsl:function name="ml:month-name" as="xs:string">
    <xsl:param name="month" as="xs:integer"/>
    <xsl:sequence select="if ($month eq  1) then 'January'
                     else if ($month eq  2) then 'February'
                     else if ($month eq  3) then 'March'
                     else if ($month eq  4) then 'April'
                     else if ($month eq  5) then 'May'
                     else if ($month eq  6) then 'June'
                     else if ($month eq  7) then 'July'
                     else if ($month eq  8) then 'August'
                     else if ($month eq  9) then 'September'
                     else if ($month eq 10) then 'October'
                     else if ($month eq 11) then 'November'
                     else if ($month eq 12) then 'December'
                     else ()"/>
  </xsl:function>


  <xsl:function name="ml:display-date" as="xs:string">
    <xsl:param name="date-or-dateTime" as="xs:string?"/>
    <xsl:variable name="date-part" select="substring($date-or-dateTime, 1, 10)"/>
    <xsl:variable name="castable" select="$date-part castable as xs:date"/>
    <xsl:choose>
      <xsl:when test="$castable">
        <xsl:variable name="dateTime" select="xs:dateTime(concat($date-part,'T00:00:00'))"/>
        <xsl:variable name="month"    select="month-from-dateTime($dateTime)"/>
        <xsl:variable name="day"      select="  day-from-dateTime($dateTime)"/>
        <xsl:variable name="year"     select=" year-from-dateTime($dateTime)"/>
        <xsl:sequence select="concat(ml:month-name($month),' ',$day,', ',$year)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$date-or-dateTime"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="ml:display-time" as="xs:string">
    <xsl:param name="dateTime" as="xs:string?"/>
    <xsl:sequence select="if ($dateTime castable as xs:dateTime) then format-dateTime(xs:dateTime($dateTime), '[h]:[m][P]')
                                                                 else $dateTime"/>
  </xsl:function>

  <xsl:function name="ml:display-date-with-time" as="xs:string">
    <xsl:param name="dateTimeGiven"/>
    <xsl:variable name="dateTime" select="string($dateTimeGiven)"/>
    
    <xsl:sequence select="if ($dateTime castable as xs:dateTime)
                          then concat(ml:display-date($dateTime),'&#160;',
                                      ml:display-time($dateTime))
                          else $dateTime"/>
  </xsl:function>

  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()*"/>
    <xsl:sequence select="ml:external-uri-main($node)"/>
  </xsl:function>

  <!-- Mapping of internal->external URIs for main server -->
  <xsl:function name="ml:external-uri-main" as="xs:string">
    <xsl:param name="node" as="node()*"/>
    <xsl:variable name="doc-path" select="base-uri($node)"/>
    <xsl:sequence select="if ($doc-path eq '/index.xml') then '/' else substring-before($doc-path, '.xml')"/>
  </xsl:function>

  <!-- Mapping of internal->external URIs for API server -->
  <xsl:function name="ml:external-uri-api" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="ml:external-uri-for-string(base-uri($node))"/>
  </xsl:function>

          <!-- Account for "/apidoc" prefix in internal/external URI mappings -->
          <xsl:function name="ml:external-uri-for-string" as="xs:string">
            <xsl:param name="doc-uri" as="xs:string"/>
            <xsl:variable name="version" select="substring-before(substring-after($doc-uri,'/apidoc/'),'/')"/>
            <xsl:variable name="versionless-path" select="if ($version) then substring-after($doc-uri,concat('/apidoc/',$version))
                                                                        else substring-after($doc-uri,'/apidoc')"/>

            <xsl:value-of>
              <!-- Map "/index.xml" to "/" and "/foo.xml" to "/foo" -->
              <xsl:value-of select="if ($versionless-path eq '/index.xml') then '/' else substring-before($versionless-path, '.xml')"/>
            </xsl:value-of>
          </xsl:function>

  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:sequence select="if ($doc-path eq '/') then '/index.xml' else concat($doc-path, '.xml')"/>
  </xsl:function>

</xsl:stylesheet>
