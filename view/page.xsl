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
  xmlns:dq   ="http://marklogic.com/disqus"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="qp xs ml xdmp dq">

  <xsl:include href="navigation.xsl"/>
  <xsl:include href="widgets.xsl"/>
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

  <xsl:variable name="content" select="/"/>

  <xsl:variable name="template" select="u:get-doc('/config/template.xhtml')"/>

  <xsl:variable name="preview-context" select="$params[@name eq 'preview-as-if-at']"/>

  <xsl:variable name="external-uri" select="if (normalize-space($preview-context)) then $preview-context
                                                                                   else ml:external-uri(/)"/>

  <xsl:variable name="site-title" select="'MarkLogic Developer Community'"/>


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
    <xsl:if test="$params[@name eq 'commented']">
      <div class="alert">Thank you for your comment. It has been submitted for moderation.</div>
    </xsl:if>
    <xsl:apply-templates mode="page-content" select="$content/*"/>
  </xsl:template>

          <xsl:template mode="page-content" match="page">
            <xsl:apply-templates/>
          </xsl:template>


          <xsl:template mode="page-content" match="Post">
            <h1>Blog</h1>
            <xsl:apply-templates mode="post-with-comments" select="."/>
          </xsl:template>

                  <xsl:template mode="post-with-comments" match="Post">
                    <xsl:apply-templates mode="blog-post" select="."/>

                    <a name="post_comment"/>
                    <!-- This will get replaced in the browser by Disqus's widget -->
                    <div id="disqus_thread">
                      <div id="dsq-content">
                        <ul id="dsq-comments">
                          <xsl:apply-templates select="ml:comments-for-page(.)/dq:reply"/>
                        </ul>
                      </div>
                    </div>

                    <!-- See http://docs.disqus.com/developers/universal/ -->
                    <script type="text/javascript">
                        var disqus_shortname = '<xsl:value-of select="$dq:shortname"/>';

                        var disqus_developer = <xsl:value-of select="$dq:developer_0_or_1"/>;

                        // The following are highly recommended additional parameters. Remove the slashes in front to use.
                        var disqus_identifier = '<xsl:value-of select="ml:disqus-identifier(.)"/>';
                        var disqus_url = 'http://developer.marklogic.com<xsl:value-of select="ml:external-uri(.)"/>';

                        function disqus_config() {
                            this.callbacks.onNewComment = [function() { setTimeout(
                                                                          function(){ $.ajax({ url: "/updateDisqusThreads" });},
                                                                          10000); } ];
                                                                          <!-- It takes a while before the API makes it available -->
                                                                          <!-- No sweat if this doesn't get called, as the scheduled
                                                                               task will pick it up. -->
                        }

                        (function() {
                            var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
                            dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
                            (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
                        })();
                    </script>
                    <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
                  </xsl:template>

                          <!-- This format is a hybrid of Wordpress and Disqus's own dynamic embed code; whatever :-) -->
                          <xsl:template match="dq:reply">
                            <li id="dsq-comment-{dq:id}">
                              <div id="dsq-comment-body-{dq:id}" class="dsq-comment-body">
                                <div class="dsq-comment-header">
                                  <div class="dsq-cite-{dq:id}">
                                    <span class="dsq-commenter-name">
                                      <a id="dsq-author-user-{dq:id}" href="{(dq:author|dq:anonymous_author)/dq:url}" target="_blank" rel="nofollow">
                                        <!-- Pick the first one from among these different possible sources for the author name -->
                                        <xsl:value-of select="( dq:author/( dq:display_name[normalize-space(.)]
                                                                          , dq:username
                                                                          )
                                                              , dq:anonymous_author/dq:name
                                                              )[1]"/>
                                      </a>
                                    </span>
                                  </div>
                                </div>
                              </div>   
                              <div id="dsq-comment-message-{dq:id}" class="dsq-comment-message">
                                <xsl:value-of select="dq:message" disable-output-escaping="yes"/> <!-- Does this not work? Do we care in this case? -->
                              </div>
                              <!-- Nested replies -->
                              <xsl:if test="dq:reply">
                                <ul>
                                  <xsl:apply-templates select="dq:reply"/>
                                </ul>
                              </xsl:if>
                            </li>
                          </xsl:template>


                          <xsl:template mode="blog-post paginated-list-item" match="Post">
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
                              <div class="action">
                                <ul>
                                  <li>
                                    <!-- This will get replaced by the actual comment count from Disqus, as described here: http://docs.disqus.com/developers/universal/#comment-count -->
                                    <a href="{ml:external-uri(.)}#disqus_thread" data-disqus-identifier="{ml:disqus-identifier(.)}">
                                      <xsl:value-of select="count(ml:comments-for-page(.)//dq:reply)"/> comments<xsl:text/>
                                    </a>
                                  </li>
                                  <li>
                                    <a rel="nofollow" href="{ml:external-uri(.)}#post_comment">Post a comment</a>
                                  </li>
                                </ul>
                              </div>
                              <!-- Script from here: http://docs.disqus.com/developers/universal/#comment-count -->
                              <script type="text/javascript">
                                  var disqus_shortname = '<xsl:value-of select="$dq:shortname"/>';

                                  (function () {
                                      var s = document.createElement('script'); s.async = true;
                                      s.type = 'text/javascript';
                                      s.src = 'http://' + disqus_shortname + '.disqus.com/count.js';
                                      (document.getElementsByTagName('HEAD')[0] || document.getElementsByTagName('BODY')[0]).appendChild(s);
                                  }());
                              </script>
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
