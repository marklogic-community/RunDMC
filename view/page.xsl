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
  <xsl:include href="xquery-imports.xsl"/>

  <xsl:output doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
              omit-xml-declaration="yes"/>

  <xsl:param name="params" as="element()*"/>
  <xsl:param name="error" as="xs:string*"/>
  <xsl:param name="errorMessage" as="xs:string*"/>
  <xsl:param name="errorDetail" as="xs:string*"/>

  <xsl:variable name="DEBUG" select="false()"/>

  <xsl:variable name="highlight-search" select="string($params[@name eq 'hl'])"/>
  <xsl:variable name="content" select="if ($highlight-search) then u:highlight-doc(/, $highlight-search) else /"/>

  <xsl:variable name="template" select="if (xdmp:uri-is-file('/config/template.optimized.xhtml'))
                                              then u:get-doc('/config/template.optimized.xhtml') 
                                              else u:get-doc('/config/template.xhtml')"/>

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


  <!-- What to put in the <title> tag -->
  <xsl:template match="page-title">
    <xsl:apply-templates mode="page-title" select="$content/*"/>
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
                    <xsl:value-of select="( xhtml:h1
                                          | xhtml:div/xhtml:h1
                                          | xhtml:h2
                                          | xhtml:div/xhtml:h2
                                          )[1]"/>
                  </xsl:template>

                  <!-- TODO: We should stop using <page> for product pages. It should change to <Product> -->
                  <xsl:template mode="page-specific-title" match="page[product-info]">
                    <xsl:value-of select="product-info/@name"/>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="page[$external-uri eq '/search']">
                    <xsl:text>Search results for "</xsl:text>
                    <xsl:value-of select="$params[@name eq 'q']"/>
                    <xsl:text>"</xsl:text>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="Project">
                    <xsl:value-of select="name"/>
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

  <!-- Process page content when we hit the <ml:page-content> element -->
  <xsl:template match="page-content">
    <xsl:if test="$DEBUG">
      <xsl:copy-of select="$params"/>
    </xsl:if>
    <xsl:apply-templates mode="page-content"    select="$content/*"/>
    <xsl:apply-templates mode="comment-section" select="$content/*"/>
  </xsl:template>

          <xsl:template mode="page-content" match="page">
            <xsl:apply-templates/>
          </xsl:template>


          <xsl:template mode="page-content" match="Post">
            <h1>Blog</h1>
            <xsl:apply-templates mode="blog-post" select="."/>
          </xsl:template>

                  <xsl:template mode="blog-post paginated-list-item" match="Post">

                    <!-- Overridden when grouped with other posts in the same page (mode="paginated-list-item");
                         Remains disabled when we're just displaying one blog post, because the comment count
                         automatically appears above the comment submit form section. Suppressing it by default
                         ensures we don't display it twice. -->
                    <xsl:param name="disable-comment-count" select="true()"/>

                    <div class="post">
                        <h2 class="title-with-links">
                            <xsl:apply-templates select="title/node()"/>
                            <a class="permalink" href="{ml:external-uri(.)}" title="Permalink"> 
                                <img src="/media/permalink.png" title="Permalink" alt="Permalink"/>
                            </a>
                        </h2>
                      <span class="date">
                        <xsl:value-of select="ml:display-date(created)"/>
                      </span>
                      <span class="author">
                        <xsl:text>by </xsl:text>
                        <xsl:apply-templates mode="author-listing" select="author"/>
                      </span>
                      <xsl:apply-templates select="body/node()"/>

                      <xsl:if test="not($disable-comment-count)">
                        <xsl:apply-templates mode="comment-count" select="."/>
                      </xsl:if>

                    </div>
                  </xsl:template>


          <xsl:template mode="page-content" match="Event">
            <h1>Events</h1>
            <h2>
              <xsl:apply-templates select="title/node()"/>
            </h2>
            <dl>
              <xsl:apply-templates mode="event-details" select="details/*"/>
            </dl>
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
            <xsl:apply-templates select="body/node()"/>
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


          <xsl:template mode="page-content" match="Announcement">
            <h1>News</h1>
            <div class="date">
              <xsl:value-of select="ml:display-date(date)"/>
            </div>
            <h2>
              <xsl:apply-templates select="title/node()"/>
            </h2>
            <xsl:apply-templates select="body/node()"/>
          </xsl:template>



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
    <xsl:sequence select="if ($castable) then format-date(xs:date($date-part), '[M01]/[D01]/[Y01]')
                                         else $date-or-dateTime"/>
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
    <xsl:variable name="doc-path" select="base-uri($node)"/>
    <xsl:sequence select="if ($doc-path eq '/index.xml') then '/' else substring-before($doc-path, '.xml')"/>
  </xsl:function>

  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:sequence select="if ($doc-path eq '/') then '/index.xml' else concat($doc-path, '.xml')"/>
  </xsl:function>

</xsl:stylesheet>
