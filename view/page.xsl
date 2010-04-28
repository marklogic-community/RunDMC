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
  <xsl:include href="tag-library.xsl"/>
  <xsl:include href="xquery-imports.xsl"/>

  <xsl:output doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
              omit-xml-declaration="yes"/>

  <xsl:param name="params" as="element()"/>

  <xsl:variable name="DEBUG" select="false()"/>

  <xsl:variable name="message" select="string($params/qp:message)"/>

  <xsl:variable name="content" select="/"/>

  <xsl:variable name="template" select="u:get-doc('/config/template.xhtml')"/>

  <xsl:variable name="external-uri" select="ml:external-uri(/)"/>

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
                                          | xhtml:h2
                                          )[1]"/>
                  </xsl:template>

                  <!-- TODO: We should stop using <page> for product pages. It should change to <Product> -->
                  <xsl:template mode="page-specific-title" match="page[product-info]">
                    <xsl:value-of select="product-info/@name"/>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="page[$external-uri eq '/search']">
                    <xsl:text>Search results for "</xsl:text>
                    <xsl:value-of select="$params/qp:q"/>
                    <xsl:text>"</xsl:text>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="Project">
                    <xsl:value-of select="name"/>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="Announcement | Event | Article | Post">
                    <xsl:value-of select="title"/>
                  </xsl:template>


  <!-- Pre-populate the search box, if applicable -->
  <xsl:template match="xhtml:input[@name eq 'q']/@ml:value">
    <xsl:attribute name="value">
      <xsl:value-of select="$params/qp:q"/>
    </xsl:attribute>
  </xsl:template>

  <!-- Process page content when we hit the <ml:page-content> element -->
  <xsl:template match="page-content">
    <xsl:if test="$DEBUG">
      <xsl:copy-of select="$params"/>
    </xsl:if>
    <!-- No need for this at the moment.
    <xsl:if test="$message">
      <div class="alert">
        <xsl:value-of select="$message"/>
      </div>
    </xsl:if>
    -->
    <xsl:if test="$params/qp:commented">
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
                    <xsl:variable name="comments-for-post" select="ml:comments-for-post(base-uri(.))"/>
                    <xsl:if test="$comments-for-post">
                      <h3 id="comments">Comments</h3>
                      <ol class="commentlist">
                        <xsl:apply-templates mode="blog-comment" select="$comments-for-post"/>
                      </ol>
                    </xsl:if>
                    <form id="post_comment" action="/controller/post-comment.xqy" method="post">
                      <input type="hidden" name="about" value="{ml:external-uri(.)}"/>
                      <fieldset>
                        <legend>Post a Comment</legend>
                        <div>
                          <label for="pc_name">Name</label>
                          <xsl:text> </xsl:text>
                          <input id="pc_name" type="text" name="author"/>
                        </div>
                        <div>
                          <label for="pc_url">URL</label>
                          <xsl:text> </xsl:text>
                          <input id="pc_url" type="text" name="url"/>
                        </div>
                        <div>
                          <label for="pc_comment">Comment</label>
                          <textarea cols="30" rows="5" id="pc_comment" name="body"/>
                        </div>
                      </fieldset>
                      <div class="submit">
                        <input type="image" src="/images/b_send.png" value="Send"/>
                      </div>
                    </form>
                  </xsl:template>

                          <xsl:template mode="blog-post paginated-list-item" match="Post">
                            <div class="post">
                              <h2>
                                <xsl:apply-templates select="title/node()"/>
                              </h2>
                              <span class="date">
                                <xsl:value-of select="ml:display-date(created)"/>
                              </span>
                              <span class="author">
                                <xsl:text>by </xsl:text>
                                <xsl:apply-templates select="author/node()"/>
                              </span>
                              <xsl:apply-templates select="body/node()"/>
                              <div class="action">
                                <ul>
                                  <li>
                                    <a href="{ml:external-uri(.)}#comments">Comments (<xsl:value-of select="count(ml:comments-for-post(base-uri(.)))"/>)</a>
                                  </li>
                                  <li>
                                    <a href="{ml:external-uri(.)}#post_comment">Post a comment</a>
                                  </li>
                                </ul>
                              </div>
                            </div>
                          </xsl:template>

                          <xsl:template mode="blog-comment" match="Comment">
                            <li>
                              <xsl:apply-templates select="body/node()"/>
                              <div class="comment_info">
                                <span class="user">
                                  <a class="tag-" href="{url}">
                                    <xsl:value-of select="author"/>
                                  </a>,
                                </span>
                                <span class="time">
                                  <xsl:value-of select="ml:display-time(created)"/>,
                                </span>
                                <span class="date">
                                  <xsl:value-of select="substring(created, 1, 10)"/>
                                </span>
                              </div>
                            </li>
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
            <div class="action repo">
              <a href="{versions/@get-involved-href}">
                Browse <xsl:value-of select="versions/@repo"/> repository
              </a>
            </div>

            <xsl:if test="versions/version">
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
                        <xsl:if test="@server-version">
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


  <xsl:function name="ml:display-date">
    <xsl:param name="date-or-dateTime" as="xs:string"/>
    <xsl:variable name="date" select="xs:date(substring($date-or-dateTime, 1, 10))"/>
    <xsl:sequence select="format-date($date, '[M01]/[D01]/[Y01]')"/>
  </xsl:function>

  <xsl:function name="ml:display-time" as="xs:string">
    <xsl:param name="dateTime" as="xs:dateTime"/>
    <xsl:sequence select="format-dateTime($dateTime, '[h]:[m][P]')"/>
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
