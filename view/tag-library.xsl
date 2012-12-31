<!-- This stylesheet contains a large list of rules for processing
     custom tags that can appear anywhere in the XML source document for
     a page on the website. These are used to insert dynamic content
     (content assembled from one or many other documents).
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:search="http://marklogic.com/appservices/search"
  xmlns:cts   ="http://marklogic.com/cts"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:qp   ="http://www.marklogic.com/ps/lib/queryparams"
  xmlns:so   ="http://marklogic.com/stackoverflow"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:srv  ="http://marklogic.com/rundmc/server-urls"
  xmlns:draft="http://developer.marklogic.com/site/internal/filter-drafts"
  xmlns:users="users"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp qp search cts srv draft">

  <xsl:variable name="page-number-supplied" select="boolean(string($params[@name eq 'p']))"/>

  <xsl:variable name="page-number" select="if ($params[@name eq 'p'] castable as xs:positiveInteger)
                                          then $params[@name eq 'p']
                                          else 1"
                as="xs:integer"/>

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
                <xsl:value-of select="u:get-doc(@href)/feature/title"/>
              </a>
            </li>
          </xsl:template>

          <xsl:template mode="feature-tab-content" match="feature">
            <xsl:variable name="feature" select="u:get-doc(@href)/feature"/>

            <div class="section" id="section{position()}">
              <div class="align_right">
                <xsl:apply-templates mode="feature-content" select="$feature/image"/>
              </div>
              <xsl:apply-templates mode="feature-content" select="$feature/(* except (title,image))"/>
            </div>
          </xsl:template>

                  <xsl:template mode="feature-content" match="image">
                    <xsl:choose>
                    <xsl:when test="@href">
                        <p align="center" class="feature">
                        <a href="{@href}" title="{@title}">
                        <img src="{@src}" alt="{@alt}">
                            <xsl:if test="@height"><xsl:attribute name="height"><xsl:value-of select="@height"/></xsl:attribute></xsl:if>
                            <xsl:if test="@width"><xsl:attribute name="width"><xsl:value-of select="@width"/></xsl:attribute></xsl:if>
                        </img>
                        </a>
                        </p>
                    </xsl:when>
                    <xsl:otherwise>
                        <p align="center" class="feature">
                        <img src="{@src}" alt="{@alt}">
                            <xsl:if test="@height"><xsl:attribute name="height"><xsl:value-of select="@height"/></xsl:attribute></xsl:if>
                            <xsl:if test="@width"><xsl:attribute name="width"><xsl:value-of select="@width"/></xsl:attribute></xsl:if>
                        </img>
                        </p>
                    </xsl:otherwise>
                    </xsl:choose>

                    <xsl:apply-templates mode="feature-content" select="caption"/>
                  </xsl:template>

                          <xsl:template mode="feature-content" match="caption">
                            <p class="caption" align="center">
                              <xsl:apply-templates/>
                            </p>
                          </xsl:template>

                  <xsl:template mode="feature-content" match="main-points">
                    <ul>
                      <xsl:apply-templates mode="feature-content" select="point"/>
                      <xsl:apply-templates mode="feature-content" select="read-more"/>
                    </ul>
                  </xsl:template>

                          <xsl:template mode="feature-content" match="point">
                            <li>
                                <xsl:copy-of select="./node()"/>
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

                  <xsl:template mode="feature-content" match="download-button">
                    <xsl:param name="is-widget" tunnel="yes"/>
                    <xsl:variable name="button-class" select="if ($is-widget) then 'download' else 'button'"/>
                    <a class="{$button-class}" href="{@href}">
                      <img src="/images/b_download_now.png" alt="Download"/>
                    </a>
                  </xsl:template>


  <xsl:template match="product-info">

    <xsl:if test="@license-page and @requirements-page">
      <ul class="info">
        <xsl:if test="@whats-new-page">
            <li><a href="{@whats-new-page}">What's New?&#160;»</a></li>
        </xsl:if>
        <li><a href="{@license-page}">Read about MarkLogic Express &#160;»</a></li>
        <xsl:if test="@academic-license-page">
            <li><a href="{@academic-license-page}">Read about the MarkLogic Academic License &#160;»</a></li>
        </xsl:if>
        <li><a href="{@requirements-page}">Review System Requirements&#160;»</a></li>
      </ul>
    </xsl:if>

    <div class="download-confirmation" id="confirm-dialog" style="display: none">
        <p>
        MarkLogic downloads are available to MarkLogic Community members. 
        </p>
        <p>
        NOTE: This MarkLogic software you are about to download is protected by copyright and other laws of the United States and/or other countries. All rights in and to this MarkLogic software are reserved in their entirety by MarkLogic Corporation and its licensors. In order to activate this MarkLogic software you are required to install a license key.  By downloading this MarkLogic software, you agree that any use of this software is strictly subject to the terms and conditions of use that you will be asked to review and accept during the installation of the license key.   If you do not accept such terms of use at that time, any further use of this MarkLogic software is strictly prohibited and you must uninstall and remove any copies of this MarkLogic software and discontinue any further use.
        </p>
    
        <xsl:if test="empty(users:getCurrentUser())">
        <p>Sign in with your MarkLogic Community credentials or <a id="confirm-dialog-signup" style="color: #01639D" href="/people/signup">Sign up</a> for free:</p>
        </xsl:if>

        <div style="margin-left: 12px; display: block" id="download-confirm-email">
            <xsl:if test="empty(users:getCurrentUser())">
                <div class="download-form-row">
                    <p id="ifail"/>
                </div>
                <div class="download-form-row">
                    <label style="width: 160px; float: left; text-align: right" for="iemail">Email:&#160;&#160;&#160;</label>
                    <input autofocus="autofocus" class="" size="30" type="text" id="iemail" name="iemail">
                        <xsl:attribute name="value">
                            <xsl:value-of select="users:getCurrentUser()/*:email"/>
                        </xsl:attribute>
                    </input>
                </div>
                <br/>
                <div class="download-form-row">
                    <label style="width: 160px; float: left; text-align: right" for="ipass">Community&#160;Password:&#160;&#160;&#160;</label>
                    <input class="" size="30" type="password" id="ipass" name="ipass"/>
                </div>
            </xsl:if>
           <br/>
           <div class="download-form-row">
               <label style="width: 160px; float: left; text-align: right" for="iaccept">&#160;</label>
               <input type="checkbox" id="iaccept" name="iaccept" value="true"/><label for="iaccept">&#160;I agree to the above terms of use.</label>
           </div>
        </div>
    </div>


    <xsl:apply-templates mode="product-platform" select="platform"/>
  </xsl:template>

          <xsl:template mode="product-platform" match="platform">
            <section class="download">
              <h3><xsl:value-of select="@name"/></h3>
              <table>
                <tbody>
                  <xsl:apply-templates mode="product-download" select="download"/>
                </tbody>
              </table>
            </section>
          </xsl:template>

                  <xsl:template mode="product-download" match="download">
                    <!--
                    <xsl:variable name="onclick" select="@md5"/>
                    -->
                    <xsl:variable name="num-cols" select="if (architecture and installer) then 3
                                                     else if (not(string(@size)))         then 1
                                                                                          else 2"/>
                    <tr>
                      <th colspan="{(3,2,1)[$num-cols]}"
                          class="{('extraWideDownloadColumn',
                                        'wideDownloadColumn',
                                                          '')[$num-cols]}">
                        <a href="{@href}" class="{@anchor-class}">
                          <xsl:apply-templates select="if ($num-cols eq 3) then architecture else node()"/>
                        </a>
                       <xsl:if test="@url-to-copy">
                            &#160;<input readonly="true" size="47" class="url-to-copy" type="text" value="{@url-to-copy}" />
                        </xsl:if>
                      </th>
                      <xsl:if test="$num-cols eq 3">
                        <td>
                          <xsl:apply-templates select="installer"/>
                        </td>
                      </xsl:if>
                      <xsl:if test="$num-cols gt 1">
                        <td>
                          <xsl:value-of select="@size"/>&#160;&#160; 
<!--
                          <xsl:if test="@md5">
                              <a href="#" onclick="alert('$md5'); return true;"> (MD5) </a>
                          </xsl:if>
-->
                        </td>
                      </xsl:if>
                    </tr>
                  </xsl:template>


  <xsl:template match="documentation-section">
    <xsl:apply-templates mode="documentation-section" select="$content/page/product-documentation"/>
  </xsl:template>

  <xsl:template match="product-documentation">
    <section id="documentation">
      <h2>Documentation <img src="/images/i_doc.png" alt="" width="28" height="31" /></h2>
      <ul>
        <xsl:apply-templates mode="product-doc-entry" select="doc | old-doc | new-doc"/>
      </ul>
    </section>
  </xsl:template>

          <xsl:template mode="product-doc-entry" match="*">
            <xsl:variable name="title">
              <xsl:apply-templates mode="product-doc-title" select="."/>
            </xsl:variable>
            <xsl:variable name="url">
              <xsl:apply-templates mode="product-doc-url" select="."/>
            </xsl:variable>
            <li>
              <a href="{$url}">

                <xsl:if test="local-name(.) ne 'new-doc'">
                    <xsl:choose>
                    <xsl:when test="ends-with(lower-case($url), 'pdf')">
                        <img src="/images/i_pdf.png" alt="View PDF for {$title}"/>
                    </xsl:when>
                    <xsl:when test="ends-with(lower-case($url), 'zip')">
                        <img src="/images/i_zip.png" alt="Download zip file for {$title}"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <img src="/images/i_documentation.png" alt="View HTML for {$title}"/>
                    </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:if test="local-name(.) eq 'new-doc'">
                  <xsl:choose>
                  <xsl:when test="@type eq 'function'">
                      <img src="/images/i_function.png" alt="{$title}"/>
                  </xsl:when>
                  <xsl:when test="@type eq 'zip'">
                      <img src="/images/i_zip.png" alt="Download zip file for {$title}"/>
                  </xsl:when>
                  <xsl:when test="@type eq 'javadoc'">
                      <img src="/images/i_java.png" alt="View {$title}"/>
                  </xsl:when>
                  <xsl:when test="@type eq 'dotnet'">
                      <img src="/images/i_dotnet.png" alt="View {$title}"/>
                  </xsl:when>
                  <xsl:otherwise>
                      <img src="/images/i_documentation.png" alt="View {$title}"/>
                  </xsl:otherwise>
                  </xsl:choose>
                </xsl:if>
                <xsl:value-of select="$title"/>
              </a>
            </li>
          </xsl:template>

                  <xsl:template mode="product-doc-title" match="old-doc">
                    <xsl:value-of select="@desc"/>
                  </xsl:template>

                  <xsl:template mode="product-doc-title" match="doc">
                    <xsl:value-of select="document(@source)/Article/title"/>
                  </xsl:template>

                  <xsl:template mode="product-doc-title" match="new-doc">
                    <xsl:variable name="version" select="if (@version) then @version else $ml:default-version"/>
                    <xsl:variable name="source" select="replace(@source, '#.*', '')"/>
                    <xsl:value-of select="if (@title) then @title else (document(concat('/apidoc/', $version, $source, '.xml'))/*/*:title)[1]/string()"/> 
                  </xsl:template>

                  <xsl:template mode="product-doc-url" match="old-doc">
                    <xsl:value-of select="@path"/>
                  </xsl:template>

                  <xsl:template mode="product-doc-url" match="doc">
                    <xsl:variable name="source" select="document(@source)"/>
                    <xsl:value-of select="if ($source/Article/external-link/@href/normalize-space(.))
                                          then $source/Article/external-link/@href
                                          else ml:external-uri($source)"/>
                  </xsl:template>

                  <xsl:template mode="product-doc-url" match="new-doc">
                    <xsl:variable name="h" select="replace('//docs.marklogic.com','//docs.marklogic.com', $srv:api-server)"/>
                    <xsl:variable name="v" select="if (@version) then concat('/', @version) else ''" />
                    <xsl:value-of select="concat($h, $v, @source)"/>
                  </xsl:template>



  <xsl:template match="top-threads">
    <xsl:variable name="threads" select="ml:get-threads-xml(@search,list/string(.))"/>
    <xsl:if test="count($threads/thread) gt 0">
      <section class="lists">
        <header>
          <h1>
            <img src="/images/logo_markmail.png" alt="MarkMail" width="135" height="31"/>
            <xsl:text> </xsl:text>
            <!-- Only display a title for the first mailing list in the list -->
            <xsl:apply-templates mode="mailing-list-title" select="list[1]"/>
            <xsl:apply-templates mode="mailing-list-subscribe-link" select="list[1]"/>
          </h1>
          <strong class="messages">
            <xsl:value-of select="$threads/@estimated-count"/>
          </strong>
        </header>
        <ul>
          <xsl:apply-templates mode="display-thread" select="for $pos in 1 to 5 return $threads/thread[$pos]"/>
        </ul>
        <ul>
          <xsl:apply-templates mode="display-thread" select="for $pos in 6 to 9 return $threads/thread[$pos]"/>
          <li class="more">
            <a href="{$threads/@all-threads-href}">All messages&#160;»</a>
          </li>
        </ul>
      </section>
    </xsl:if>
  </xsl:template>

          <xsl:template mode="mailing-list-title" match="list[. eq 'com.marklogic.developer.general']">MarkLogic Dev General</xsl:template>
          <xsl:template mode="mailing-list-title" match="list[. eq 'com.marklogic.developer.commits']">Commits</xsl:template>
          <xsl:template mode="mailing-list-title" match="list[. eq 'com.marklogic.developer.usergroups']">User Group mailing lists</xsl:template>
          <xsl:template mode="mailing-list-title" match="list">
            <xsl:value-of select="."/>
          </xsl:template>

          <xsl:template mode="mailing-list-subscribe-link" match="*"/>
          <xsl:template mode="mailing-list-subscribe-link" match="list[. = ('com.marklogic.developer.general',
                                                                            'com.marklogic.developer.commits')]">
            <xsl:variable name="href">
              <xsl:apply-templates mode="mailing-list-subscribe-url" select="."/>
            </xsl:variable>
            <xsl:text> (</xsl:text>
            <a href="{$href}">subscribe</a>
            <xsl:text>)</xsl:text>
          </xsl:template>

          <xsl:template mode="mailing-list-subscribe-url"  match="list[. eq 'com.marklogic.developer.general']">/mailman/listinfo/general</xsl:template>
          <xsl:template mode="mailing-list-subscribe-url"  match="list[. eq 'com.marklogic.developer.commits']">/mailman/listinfo/commits</xsl:template>



          <xsl:template mode="display-thread" match="thread">            
            <li>
              <a href="{@href}" title="{blurb}">
                <xsl:value-of select="@title"/>
              </a>
              <div class="author_date">
                <a href="{author/@href}">
                  <xsl:value-of select="author"/>
                </a>
                <xsl:text>, </xsl:text>
                <span class="date">
                  <xsl:value-of select="@date"/>
                </span>
              </div>
            </li>
          </xsl:template>

  <xsl:template match="stackoverflow-reflector">
    <div id="stackunderflow"/>
    <script type="text/javascript">
        $(function() {
            stackunderflow.getQuestionsWithBodyWithTags("marklogic", 7).render("#stackunderflow");
        });
    </script>
  </xsl:template>

  <xsl:template match="stackoverflow-widget">
    <div id="stackunderflow-widget"/>
    <script type="text/javascript">
        $(function() {
            stackunderflow.getQuestionsWithBodyWithTags("marklogic", 3).render("#stackunderflow-widget", 'widget', 
                function() {
                    $('article.so-widget').unwrap();
                }
            );
        });
    </script>
  </xsl:template>

  <xsl:template match="upcoming-user-group-events">
    <xsl:variable name="upcoming-events" select="ml:get-meetup-upcoming(@group)"/>
    <xsl:variable name="recent-events" select="ml:get-meetup-recent(@group)"/>
    <xsl:if test="(count($upcoming-events) gt 0) or (count($recent-events) gt 0)">
    <section class="lists meetup">
      <header>
        <h1><img src="/images/i_meetup_lg.png" alt="Meetup" width="56" height="37" /><xsl:value-of select="ml:get-meetup-name(@group)"/></h1>
        <a><xsl:attribute name="href"><xsl:value-of select="concat('http://meetup.com/', @group)"/></xsl:attribute> More information&#160;»</a>
      </header>
      <xsl:if test="count($upcoming-events) gt 0">
      <section>
        <h2>Upcoming Meetups</h2>
        <ul>
        <xsl:apply-templates mode="meetup-events" select="$upcoming-events"/>
        </ul>
      </section>
      </xsl:if>
      <xsl:if test="count($recent-events) gt 0">
      <section>
        <h2>Recent Meetups</h2>
        <ul>
        <xsl:apply-templates mode="meetup-events" select="$recent-events"/>
        </ul>
      </section>
      </xsl:if>
    </section>
    </xsl:if>
  </xsl:template>

      <xsl:template mode="meetup-events" match="meetup" >
          <li>
            <div class="info">
              <div class="date"><xsl:value-of select="date"/></div>
              <a class="title">
                <xsl:attribute name="href"><xsl:value-of select="url/string()"/></xsl:attribute>
                <xsl:value-of select="title/string()"/>
              </a>
            </div>
            <div class="attendees">
              <xsl:apply-templates mode="meetup-members" select="rsvps/member" />
              <span class="amount">
                <xsl:value-of select="yes-rsvps"/>
              </span>
            </div>
          </li>
      </xsl:template>

      <xsl:template mode="meetup-members" match="member" >
          <xsl:variable name="url" select="concat('http://meetup.com/members/', id)" />
          <xsl:variable name="avatar" select="avatar"/>
          <xsl:variable name="name" select="name"/>
          <a title="{$name}" href="{$url}"><img src="{$avatar}" title="{$name}" alt="{$name}" width="24" height="24" /></a>
      </xsl:template>


  <xsl:template match="latest-posts">
    <xsl:apply-templates mode="latest-post" select="ml:latest-posts(@how-many)">
       <xsl:with-param name="show-icon" select="false()"/>
    </xsl:apply-templates>
  </xsl:template>

          <!-- ASSUMPTION: We're not adding new <Announcement> docs anymore, so they won't appear as the latest -->
          <xsl:template mode="latest-post" match="Post | Event">
            <xsl:param name="show-icon" select="true()"/>
            <article>
              <h4>
                <xsl:if test="$show-icon">
                  <xsl:apply-templates mode="latest-post-icon" select="."/>
                </xsl:if>
                <a href="{ml:external-uri(.)}">
                  <xsl:apply-templates mode="page-specific-title" select="."/>
                </a>
              </h4>
              <xsl:apply-templates mode="post-date-info" select="."/>
              <div>
                <xsl:value-of select="short-description"/>
              </div>
            </article>
          </xsl:template>

                  <xsl:template mode="latest-post-icon" match="Post">
                    <img width="36" height="33" src="/images/i_rss.png" alt="Blog post"/>
                  </xsl:template>

                  <xsl:template mode="latest-post-icon" match="Event">
                    <img width="40" height="32" src="/images/i_calendar.png" alt="Event"/>
                  </xsl:template>


                  <xsl:template mode="post-date-info" match="Post">
                    <div class="author_date">
                      <xsl:text>by </xsl:text>
                      <xsl:apply-templates mode="author-listing" select="author"/>
                      <xsl:text>, </xsl:text>
                      <xsl:value-of select="ml:display-date(created)"/>
                    </div>
                  </xsl:template>

                  <xsl:template mode="post-date-info" match="Event">
                    <div class="author_date">
                      Event date: <xsl:value-of select="ml:display-date(details/date)"/>
                    </div>
                  </xsl:template>


  <xsl:template match="recent-news-and-events">
    <xsl:variable name="announcement" select="ml:latest-announcement()"/>
    <xsl:variable name="event"        select="ml:most-recent-event()"/>
    <xsl:variable name="events-by-date" select="ml:events-by-date()"/>
    <xsl:variable name="announcements-by-date" select="ml:announcements-by-date()"/>
    <div class="double">
      <div>
        <h2>News</h2>
        <xsl:apply-templates mode="news-excerpt" select="$announcement | $announcements-by-date[2][current()/@include-second-announcement]">
          <xsl:with-param name="suppress-more-link" select="string(@suppress-more-links) eq 'yes'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
      <div>
        <h2>Events</h2>
        <xsl:apply-templates mode="event-excerpt" select="$event | $events-by-date[2][current()/@include-second-event] ">
          <xsl:with-param name="suppress-more-link" select="string(@suppress-more-links) eq 'yes'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
    </div>
  </xsl:template>

          <xsl:template mode="news-excerpt" match="Announcement">
            <xsl:param name="read-more-inline" tunnel="yes"/>
            <h3>
              <xsl:apply-templates select="title/node()"/>
            </h3>
            <p>
              <xsl:apply-templates select="body//teaser/node()"/>
              <xsl:if test="$read-more-inline">
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="read-more" select="."/>
              </xsl:if>
            </p>
            <p>
            <xsl:if test="not($read-more-inline)">
              <xsl:apply-templates mode="read-more" select="."/>
            </xsl:if>
            </p>
            <xsl:apply-templates mode="more-link" select="."/>
          </xsl:template>

                  <xsl:template mode="read-more" match="Announcement | Event">
                    <a class="more" href="{ml:external-uri(.)}">Read more&#160;></a>
                  </xsl:template>


          <xsl:template mode="event-excerpt" match="Event">
            <xsl:param name="suppress-description" tunnel="yes"/>
            <h3>
              <xsl:apply-templates select="title/node()"/>
            </h3>
            <xsl:if test="not($suppress-description)">
              <xsl:apply-templates select="description//teaser/node()"/>
            </xsl:if>
            <dl>
              <xsl:apply-templates mode="event-details" select="details/*"/>
            </dl>
            <a class="more" href="{ml:external-uri(.)}">More information&#160;></a>
            <xsl:apply-templates mode="more-link" select="."/>
            <xsl:if test="position() != last()">
                <br/> &#160; <br/> &#160; <br/>
            </xsl:if>
          </xsl:template>

                  <xsl:template mode="more-link" match="*">
                    <xsl:param name="suppress-more-link" tunnel="yes" as="xs:boolean" select="false()"/>
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

                          <xsl:template mode="more-link-href" match="Event"       >/events</xsl:template>
                          <xsl:template mode="more-link-href" match="Announcement">/news</xsl:template>

                          <xsl:template mode="more-link-text" match="Event"       >More Events</xsl:template>
                          <xsl:template mode="more-link-text" match="Announcement">More News</xsl:template>


                  <!-- TODO: For dates and times, consider use ISO 8601 format (in the source data) instead -->
                  <xsl:template mode="event-details" match="*">
                    <tr>
                      <th scope="row">
                        <xsl:apply-templates mode="event-detail-name" select="."/>
                        <xsl:text>:</xsl:text>
                      </th>
                      <td>
                        <xsl:apply-templates/>
                      </td>
                    </tr>
                  </xsl:template>

                          <xsl:template mode="event-detail-name" match="date"     >Date</xsl:template>
                          <xsl:template mode="event-detail-name" match="time"     >Time</xsl:template>
                          <xsl:template mode="event-detail-name" match="location" >Location</xsl:template>
                          <xsl:template mode="event-detail-name" match="topic"    >Topic</xsl:template>
                          <xsl:template mode="event-detail-name" match="presenter">Presenter</xsl:template>


  <xsl:template match="article-abstract">
    <xsl:apply-templates mode="article-abstract" select="document(@href)/*">
      <xsl:with-param name="heading" select="@heading"/>
      <xsl:with-param name="suppress-byline" select="true()"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="recent-article">
    <xsl:apply-templates mode="article-abstract" select="ml:latest-article(string(@type))">
      <xsl:with-param name="heading" select="@heading"/>
    </xsl:apply-templates>
  </xsl:template>

          <xsl:template mode="article-abstract" match="Article | Post">
            <xsl:param name="heading" as="xs:string"/>
            <xsl:param name="suppress-byline"/>
            <div class="single">
              <h2>
                <xsl:value-of select="$heading"/>
              </h2>
              <h3>
                <xsl:apply-templates select="title/node()"/>
              </h3>
              <xsl:if test="not($suppress-byline)">
                <div class="author">
                  <xsl:text>By </xsl:text>
                  <xsl:apply-templates mode="author-listing" select="author"/>
                </div>
              </xsl:if>
              <p style="line-height: 150%">
                <xsl:apply-templates select="if (normalize-space(abstract)) then abstract/node()
                                                                            else body/xhtml:p[1]/node()"/>
                <xsl:text> </xsl:text>
              </p>
              <p>
                <a class="more" href="{ml:external-uri(.)}">Read&#160;more&#160;></a>
              </p>
            </div>
          </xsl:template>


  <xsl:template match="read-more">
    <a class="more" href="{@href}">Read&#160;more&#160;></a>
  </xsl:template>

  <!-- Not currently used
  <xsl:template match="license-options">
    <div class="action">
      <ul>
        <li>
          <a href="{@href}">License options</a>
        </li>
      </ul>
    </div>
  </xsl:template>
  -->


  <xsl:template match="document-list">
    <xsl:variable name="docs" select="ml:lookup-articles(string(@type), string(@server-version), string(@topic), boolean(@allow-unversioned-docs))"/>
    <div class="doclist">
      <h2>&#160;</h2>
      <!-- 2.0 feature TODO: add pagination -->
      <span class="amount">
        <!--
        <xsl:value-of select="count($docs)"/>
        <xsl:text> of </xsl:text>
        -->
<!--
        <xsl:value-of select="count($docs)"/>
        <xsl:choose>
            <xsl:when test="count($docs) eq 1">
                <xsl:text> document</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> documents</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
-->
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
      <table class="sortable documentsList">
        <colgroup>
          <col class="col1"/>
          <!--
          <col class="col2"/>
          <col class="col3"/>
          -->
          <!--
          <col class="col4"/>
          -->
        </colgroup>
        <thead>
          <tr>
            <th scope="col">Title</th>
            <!--<th scope="col">Document&#160;Type&#160;&#160;&#160;&#160;</th>--> <!-- nbsp's to prevent overlap with sort arrow -->
            <!--
            <th scope="col">Server&#160;Version&#160;&#160;&#160;&#160;</th>
            <th scope="col">Topic(s)</th>
            -->
            <!--
            <th scope="col" class="sort">Last&#160;updated</th>
            -->
          </tr>
        </thead>
        <tbody>
          <xsl:apply-templates mode="doc-listing" select="$docs"/>
        </tbody>
      </table>
    </div>
  </xsl:template>

  <!-- ASSUMPTION: <doc> children of <guide-list> only appear at the beginning;
                   after that, they all appear inside child <guide-group> elements. -->
  <xsl:template match="guide-list/doc"/>
  <xsl:template match="guide-list/doc[1]
                     | guide-group" priority="1">
    <ul class="doclist">
      <xsl:apply-templates mode="guide-list-item" select="for $path in ( self::doc/..
                                                                       | self::guide-group
                                                                       )/doc/@path
                                                          return document($path)/Article"/>
    </ul>
  </xsl:template>

  <xsl:template match="guide-group" priority="2">
    <h3><xsl:value-of select="@name"/></h3>
    <xsl:next-match/>
  </xsl:template>

          <xsl:template mode="guide-list-item" match="Article">
            <xsl:variable name="uri" select="external-link/@href"/>
            <li>
                <a href="{$uri}">
                  <xsl:value-of select="title"/>
                </a>
                <xsl:call-template name="edit-link">
                  <xsl:with-param name="src-doc" select="root(.)"/>
                </xsl:call-template>
                <xsl:if test="ends-with($uri,'.pdf')">
                  <xsl:text> | </xsl:text>
                  <img src="/images/i_pdf.png" alt="(PDF)" width="25" height="26"/>
                </xsl:if>
                <div><xsl:value-of select="description"/></div>
            </li>
          </xsl:template>


  <xsl:template match="topic-docs">
    <ul class="doclist">
      <xsl:variable name="explicitly-listed" select="for $path in doc/@path return doc($path)/*"/> <!-- for enforces order -->
      <!-- List the manual ones first, in the given order -->
      <xsl:apply-templates mode="topic-doc" select="$explicitly-listed"/>
      <!-- Then list other docs with this topic tag -->
      <xsl:apply-templates mode="topic-doc" select="ml:topic-docs(@tag)/* except $explicitly-listed"/>
    </ul>
  </xsl:template>

          <xsl:template mode="topic-doc" match="*">
            <li>
              <a href="{ml:external-uri(.)}">
                <xsl:apply-templates mode="page-specific-title" select="."/>
              </a>
              <xsl:call-template name="edit-link">
                <xsl:with-param name="src-doc" select="root(.)"/>
              </xsl:call-template>
              <div>
                <xsl:apply-templates select="(short-description,description)[1]/node()"/>
              </div>
            </li>
          </xsl:template>


  <xsl:template match="edit-link" name="edit-link">
    <xsl:param name="src-doc" select="$original-content"/>
    <xsl:if test="not($draft:public-docs-only)">
      <xsl:variable name="edit-link-path">
        <xsl:apply-templates mode="edit-link-path" select="$src-doc/*"/>
      </xsl:variable>
      <xsl:text> (</xsl:text>
      <a href="{$srv:admin-server}{$edit-link-path}/edit?~doc_path={base-uri($src-doc)}">edit</a>
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:template>

          <xsl:template mode="edit-link-path" match="Project     ">/code</xsl:template>
          <xsl:template mode="edit-link-path" match="Article     ">/learn</xsl:template>
          <xsl:template mode="edit-link-path" match="Post        ">/blog</xsl:template>
          <xsl:template mode="edit-link-path" match="Announcement">/news</xsl:template>
          <xsl:template mode="edit-link-path" match="Event       ">/events</xsl:template>
          <xsl:template mode="edit-link-path" match="page        ">/pages</xsl:template>


  <xsl:template match="document-table">
    <xsl:variable name="docs" select="doc"/>
    <div class="doclist">
      <h2>&#160;</h2>
      <span class="amount">
<!--
        <xsl:value-of select="count($docs)"/>
        <xsl:choose>
            <xsl:when test="count($docs) eq 1">
                <xsl:text> document</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> documents</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
-->
      </span>
      <table class="sortable documentsList"><!--documentsTable">-->
        <colgroup>
          <col class="col1"/>
          <!-- Display last updated only on latest version -->
          <!--
          <xsl:if test="not(exists(@version))">
            <col class="col2"/>
          </xsl:if>
          -->
        </colgroup>
        <thead>
          <tr>
            <th scope="col">Title</th>
            <!--
            <th scope="col">Last&#160;updated</th>
            -->
          </tr>
        </thead>
        <tbody>
          <xsl:apply-templates mode="doc-table-listing" select="doc"/>
        </tbody>
      </table>
    </div>
  </xsl:template>

          <xsl:template mode="doc-table-listing" match="doc">
              <xsl:variable name="version" select="string(../@version)" />
              <xsl:apply-templates mode="doc-table-entry" select="document(@path)/Article">
                <xsl:with-param name="version" select="$version" />
              </xsl:apply-templates>
          </xsl:template>

          <xsl:template mode="doc-table-entry" match="Article">
            <xsl:param name="version" />
            <tr>
              <xsl:if test="position() mod 2 eq 0">
                <xsl:attribute name="class">alt</xsl:attribute>
              </xsl:if>
              <td>
                <img src="/images/i_monitor.png" alt="" width="24" height="22" />
                <a href="{ ml:external-uri(.) }">
                  <xsl:value-of select="title"/>
                </a>
                <br/><div class="doc-desc"><xsl:value-of select="description"/></div>
              </td>
        
              <!--
              <td>
                  <xsl:value-of select="replace(last-updated,' ','&#160;')"/>
              </td>
              -->
            </tr>
          </xsl:template>

          <xsl:template mode="doc-listing" match="Article">
            <tr>
              <xsl:if test="position() mod 2 eq 0">
                <xsl:attribute name="class">alt</xsl:attribute>
              </xsl:if>
              <td>
                <a href="{ ml:external-uri(.)}">
                  <xsl:value-of select="title"/>
                </a>
                <br/><div class="doc-desc"><p><xsl:value-of select="description"/></p></div>
              </td>
              <!--
              <td>
                <xsl:value-of select="replace(@type,' ','&#160;')"/>
              </td>
              -->
              <!--
              <td>
                <xsl:value-of select="replace(last-updated,' ','&#160;')"/>
              </td>
              -->
            </tr>
          </xsl:template>


  <!-- Paginated list for blog posts, events, and news announcements -->
  <xsl:template match="paginated-list">
    <xsl:variable name="results-per-page" select="xs:integer(@results-per-page)"/>
    <xsl:variable name="start" select="ml:start-index($results-per-page)"/>

    <xsl:apply-templates mode="paginated-list-item" select="ml:list-segment-of-docs($start, $results-per-page, @type)">
      <xsl:with-param name="in-paginated-list" select="true()" tunnel="yes"/>
    </xsl:apply-templates>

    <xsl:variable name="page-url">
      <xsl:apply-templates mode="paginated-page-url" select="."/>
    </xsl:variable>

    <xsl:variable name="older" select="ml:total-doc-count(@type) gt ($start + $results-per-page - 1)"/>
    <xsl:variable name="newer" select="$page-number gt 1"/>
    <div class="pagination">
      <xsl:choose>
        <xsl:when test="$older">
          <a href="{$page-url}?p={$page-number + 1}">«&#160;Older entries</a>
        </xsl:when>
        <xsl:otherwise>
          <span>«&#160;Older entries</span>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text> | </xsl:text>
      <xsl:choose>
        <xsl:when test="$newer">
          <a href="{$page-url}?p={$page-number - 1}">Newer entries&#160;»</a>
        </xsl:when>
        <xsl:otherwise>
          <span>Newer entries&#160;»</span>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

          <xsl:template mode="paginated-page-url" match="Announcement">/news</xsl:template>
          <xsl:template mode="paginated-page-url" match="Event"       >/events</xsl:template>
          <xsl:template mode="paginated-page-url" match="Post"        >/blog</xsl:template>

          <xsl:function name="ml:start-index" as="xs:integer">
            <xsl:param name="results-per-page" as="xs:integer"/>
            <xsl:sequence select="($results-per-page * $page-number) - ($results-per-page - 1)"/>
          </xsl:function>


  <xsl:template match="elapsed-time">
    <div style="display: none"><xsl:value-of select="xdmp:elapsed-time()"/></div>
  </xsl:template>

  <xsl:template match="short-description"/>

  <xsl:template match="server-version">
    <span class="server-version"><xsl:value-of select="xdmp:version()"/></span>
  </xsl:template>

  <xsl:template match="user-name">
    <xsl:value-of select="users:getCurrentUser()/*:name/string()"/>
  </xsl:template>

  <xsl:template match="first-name">
    <xsl:value-of select="fn:tokenize(users:getCurrentUser()/*:name/string(), ' ')[1]"/>
  </xsl:template>

  <xsl:template match="last-name">
    <xsl:value-of select="users:getCurrentUser()/*:name/string()"/>
  </xsl:template>

  <xsl:template match="profile">
    <xsl:variable name="user" select="users:getCurrentUser()"/>
    <div>
    <fieldset>
        <div class="profile-form-row">
            <div class="profile-form-label">Email </div>
            <input disabled="disabled" readonly="readonly" class="email" id="email" name="email" value="{$user/*:email/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Name </div>
            <input autofocus="autofocus" class="required" id="name" name="name" value="{$user/*:name/string()}" type="text"/>
        </div>
        <!--
        <div class="profile-form-row">
            <div class="profile-form-label">Avatar</div>
            <input class="url" id="picture" name="picture" value="{$user/*:picture/string()}" type="text"/>
            <img src="{$user/*:picture/string()}" alt="picture"/>
        </div>
        -->
        <div class="profile-form-row">
            <div class="profile-form-label">Website/Blog</div>
            <input class="url" id="url" name="url" value="{$user/*:url/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Twitter</div>
            <input class="twitter" id="twitter" name="twitter" value="{$user/*:twitter/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Phone</div>
            <input class="phone" id="phone" name="phone" value="{$user/*:phone/string()}" type="text"/>
        </div>
        <!--
        <div class="profile-form-row">
            <div class="profile-form-label">Password</div>
            <input class="password required" id="password" name="password" value="" type="password"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Confirm password</div>
            <input id="password_confirm" name="password_confirm" value="" type="password"/>
        </div>
        -->
        <div class="profile-form-row">
            <div class="profile-form-label">City </div>
            <input class="required" id="city" name="city" value="{$user/*:city/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">State </div>
            <input class="required" id="state" name="state" value="{$user/*:state/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Zip/Postal Code </div>
            <input class="required" id="zip" name="zip" value="{$user/*:zip/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Country </div>
            <select class="required countrypicker" id="country" name="country" data-initvalue="{$user/*:country/string()}" autocorrect="off" autocomplete="off">
              <option value="Afghanistan" data-alternative-spellings="AF افغانستان">Afghanistan</option>
              <option value="Åland Islands" data-alternative-spellings="AX Aaland Aland" data-relevancy-booster="0.5">Åland Islands</option>
              <option value="Albania" data-alternative-spellings="AL">Albania</option>
              <option value="Algeria" data-alternative-spellings="DZ الجزائر">Algeria</option>
              <option value="American Samoa" data-alternative-spellings="AS" data-relevancy-booster="0.5">American Samoa</option>
              <option value="Andorra" data-alternative-spellings="AD" data-relevancy-booster="0.5">Andorra</option>
              <option value="Angola" data-alternative-spellings="AO">Angola</option>
              <option value="Anguilla" data-alternative-spellings="AI" data-relevancy-booster="0.5">Anguilla</option>
              <option value="Antarctica" data-alternative-spellings="AQ" data-relevancy-booster="0.5">Antarctica</option>
              <option value="Antigua And Barbuda" data-alternative-spellings="AG" data-relevancy-booster="0.5">Antigua And Barbuda</option>
              <option value="Argentina" data-alternative-spellings="AR">Argentina</option>
              <option value="Armenia" data-alternative-spellings="AM Հայաստան">Armenia</option>
              <option value="Aruba" data-alternative-spellings="AW" data-relevancy-booster="0.5">Aruba</option>
              <option value="Australia" data-alternative-spellings="AU" data-relevancy-booster="1.5">Australia</option>
              <option value="Austria" data-alternative-spellings="AT Österreich Osterreich Oesterreich ">Austria</option>
              <option value="Azerbaijan" data-alternative-spellings="AZ">Azerbaijan</option>
              <option value="Bahamas" data-alternative-spellings="BS">Bahamas</option>
              <option value="Bahrain" data-alternative-spellings="BH البحرين">Bahrain</option>
              <option value="Bangladesh" data-alternative-spellings="BD বাংলাদেশ" data-relevancy-booster="2">Bangladesh</option>
              <option value="Barbados" data-alternative-spellings="BB">Barbados</option>
              <option value="Belarus" data-alternative-spellings="BY Беларусь">Belarus</option>
              <option value="Belgium" data-alternative-spellings="BE België Belgie Belgien Belgique" data-relevancy-booster="1.5">Belgium</option>
              <option value="Belize" data-alternative-spellings="BZ">Belize</option>
              <option value="Benin" data-alternative-spellings="BJ">Benin</option>
              <option value="Bermuda" data-alternative-spellings="BM" data-relevancy-booster="0.5">Bermuda</option>
              <option value="Bhutan" data-alternative-spellings="BT भूटान">Bhutan</option>
              <option value="Bolivia" data-alternative-spellings="BO">Bolivia</option>
              <option value="Bonaire, Sint Eustatius and Saba" data-alternative-spellings="BQ">Bonaire, Sint Eustatius and Saba</option>
              <option value="Bosnia and Herzegovina" data-alternative-spellings="BA Босна и Херцеговина">Bosnia and Herzegovina</option>
              <option value="Botswana" data-alternative-spellings="BW">Botswana</option>
              <option value="Bouvet Island" data-alternative-spellings="BV">Bouvet Island</option>
              <option value="Brazil" data-alternative-spellings="BR Brasil" data-relevancy-booster="2">Brazil</option>
              <option value="British Indian Ocean Territory" data-alternative-spellings="IO">British Indian Ocean Territory</option>
              <option value="Brunei Darussalam" data-alternative-spellings="BN">Brunei Darussalam</option>
              <option value="Bulgaria" data-alternative-spellings="BG България">Bulgaria</option>
              <option value="Burkina Faso" data-alternative-spellings="BF">Burkina Faso</option>
              <option value="Burundi" data-alternative-spellings="BI">Burundi</option>
              <option value="Cambodia" data-alternative-spellings="KH កម្ពុជា">Cambodia</option>
              <option value="Cameroon" data-alternative-spellings="CM">Cameroon</option>
              <option value="Canada" data-alternative-spellings="CA" data-relevancy-booster="2">Canada</option>
              <option value="Cape Verde" data-alternative-spellings="CV Cabo">Cape Verde</option>
              <option value="Cayman Islands" data-alternative-spellings="KY" data-relevancy-booster="0.5">Cayman Islands</option>
              <option value="Central African Republic" data-alternative-spellings="CF">Central African Republic</option>
              <option value="Chad" data-alternative-spellings="TD تشاد‎ Tchad">Chad</option>
              <option value="Chile" data-alternative-spellings="CL">Chile</option>
              <option value="China" data-relevancy-booster="3.5" data-alternative-spellings="CN Zhongguo Zhonghua Peoples Republic 中国/中华">China</option>
              <option value="Christmas Island" data-alternative-spellings="CX" data-relevancy-booster="0.5">Christmas Island</option>
              <option value="Cocos (Keeling) Islands" data-alternative-spellings="CC" data-relevancy-booster="0.5">Cocos (Keeling) Islands</option>
              <option value="Colombia" data-alternative-spellings="CO">Colombia</option>
              <option value="Comoros" data-alternative-spellings="KM جزر القمر">Comoros</option>
              <option value="Congo" data-alternative-spellings="CG">Congo</option>
              <option value="Congo, the Democratic Republic of the" data-alternative-spellings="CD Congo-Brazzaville Repubilika ya Kongo">Congo, the Democratic Republic of the</option>
              <option value="Cook Islands" data-alternative-spellings="CK" data-relevancy-booster="0.5">Cook Islands</option>
              <option value="Costa Rica" data-alternative-spellings="CR">Costa Rica</option>
              <option value="Côte d'Ivoire" data-alternative-spellings="CI Cote dIvoire">Côte d'Ivoire</option>
              <option value="Croatia" data-alternative-spellings="HR Hrvatska">Croatia</option>
              <option value="Cuba" data-alternative-spellings="CU">Cuba</option>
              <option value="Curaçao" data-alternative-spellings="CW Curacao">Curaçao</option>
              <option value="Cyprus" data-alternative-spellings="CY Κύπρος Kýpros Kıbrıs">Cyprus</option>
              <option value="Czech Republic" data-alternative-spellings="CZ Česká Ceska">Czech Republic</option>
              <option value="Denmark" data-alternative-spellings="DK Danmark" data-relevancy-booster="1.5">Denmark</option>
              <option value="Djibouti" data-alternative-spellings="DJ جيبوتي‎ Jabuuti Gabuuti">Djibouti</option>
              <option value="Dominica" data-alternative-spellings="DM Dominique" data-relevancy-booster="0.5">Dominica</option>
              <option value="Dominican Republic" data-alternative-spellings="DO">Dominican Republic</option>
              <option value="Ecuador" data-alternative-spellings="EC">Ecuador</option>
              <option value="Egypt" data-alternative-spellings="EG" data-relevancy-booster="1.5">Egypt</option>
              <option value="El Salvador" data-alternative-spellings="SV">El Salvador</option>
              <option value="Equatorial Guinea" data-alternative-spellings="GQ">Equatorial Guinea</option>
              <option value="Eritrea" data-alternative-spellings="ER إرتريا ኤርትራ">Eritrea</option>
              <option value="Estonia" data-alternative-spellings="EE Eesti">Estonia</option>
              <option value="Ethiopia" data-alternative-spellings="ET ኢትዮጵያ">Ethiopia</option>
              <option value="Falkland Islands (Malvinas)" data-alternative-spellings="FK" data-relevancy-booster="0.5">Falkland Islands (Malvinas)</option>
              <option value="Faroe Islands" data-alternative-spellings="FO Føroyar Færøerne" data-relevancy-booster="0.5">Faroe Islands</option>
              <option value="Fiji" data-alternative-spellings="FJ Viti फ़िजी">Fiji</option>
              <option value="Finland" data-alternative-spellings="FI Suomi">Finland</option>
              <option value="France" data-alternative-spellings="FR République française" data-relevancy-booster="2.5">France</option>
              <option value="French Guiana" data-alternative-spellings="GF">French Guiana</option>
              <option value="French Polynesia" data-alternative-spellings="PF Polynésie française">French Polynesia</option>
              <option value="French Southern Territories" data-alternative-spellings="TF">French Southern Territories</option>
              <option value="Gabon" data-alternative-spellings="GA République Gabonaise">Gabon</option>
              <option value="Gambia" data-alternative-spellings="GM">Gambia</option>
              <option value="Georgia" data-alternative-spellings="GE საქართველო">Georgia</option>
              <option value="Germany" data-alternative-spellings="DE Bundesrepublik Deutschland" data-relevancy-booster="3">Germany</option>
              <option value="Ghana" data-alternative-spellings="GH">Ghana</option>
              <option value="Gibraltar" data-alternative-spellings="GI" data-relevancy-booster="0.5">Gibraltar</option>
              <option value="Greece" data-alternative-spellings="GR Ελλάδα" data-relevancy-booster="1.5">Greece</option>
              <option value="Greenland" data-alternative-spellings="GL grønland" data-relevancy-booster="0.5">Greenland</option>
              <option value="Grenada" data-alternative-spellings="GD">Grenada</option>
              <option value="Guadeloupe" data-alternative-spellings="GP">Guadeloupe</option>
              <option value="Guam" data-alternative-spellings="GU">Guam</option>
              <option value="Guatemala" data-alternative-spellings="GT">Guatemala</option>
              <option value="Guernsey" data-alternative-spellings="GG" data-relevancy-booster="0.5">Guernsey</option>
              <option value="Guinea" data-alternative-spellings="GN">Guinea</option>
              <option value="Guinea-Bissau" data-alternative-spellings="GW">Guinea-Bissau</option>
              <option value="Guyana" data-alternative-spellings="GY">Guyana</option>
              <option value="Haiti" data-alternative-spellings="HT">Haiti</option>
              <option value="Heard Island and McDonald Islands" data-alternative-spellings="HM">Heard Island and McDonald Islands</option>
              <option value="Holy See (Vatican City State)" data-alternative-spellings="VA" data-relevancy-booster="0.5">Holy See (Vatican City State)</option>
              <option value="Honduras" data-alternative-spellings="HN">Honduras</option>
              <option value="Hong Kong" data-alternative-spellings="HK 香港">Hong Kong</option>
              <option value="Hungary" data-alternative-spellings="HU Magyarország">Hungary</option>
              <option value="Iceland" data-alternative-spellings="IS Island">Iceland</option>
              <option value="India" data-alternative-spellings="IN भारत गणराज्य Hindustan" data-relevancy-booster="3">India</option>
              <option value="Indonesia" data-alternative-spellings="ID" data-relevancy-booster="2">Indonesia</option>
              <option value="Iran, Islamic Republic of" data-alternative-spellings="IR ایران">Iran, Islamic Republic of</option>
              <option value="Iraq" data-alternative-spellings="IQ العراق‎">Iraq</option>
              <option value="Ireland" data-alternative-spellings="IE Éire" data-relevancy-booster="1.2">Ireland</option>
              <option value="Isle of Man" data-alternative-spellings="IM" data-relevancy-booster="0.5">Isle of Man</option>
              <option value="Israel" data-alternative-spellings="IL إسرائيل ישראל">Israel</option>
              <option value="Italy" data-alternative-spellings="IT Italia" data-relevancy-booster="2">Italy</option>
              <option value="Jamaica" data-alternative-spellings="JM">Jamaica</option>
              <option value="Japan" data-alternative-spellings="JP Nippon Nihon 日本" data-relevancy-booster="2.5">Japan</option>
              <option value="Jersey" data-alternative-spellings="JE" data-relevancy-booster="0.5">Jersey</option>
              <option value="Jordan" data-alternative-spellings="JO الأردن">Jordan</option>
              <option value="Kazakhstan" data-alternative-spellings="KZ Қазақстан Казахстан">Kazakhstan</option>
              <option value="Kenya" data-alternative-spellings="KE">Kenya</option>
              <option value="Kiribati" data-alternative-spellings="KI">Kiribati</option>
              <option value="Korea, Democratic People's Republic of" data-alternative-spellings="KP North Korea">Korea, Democratic People's Republic of</option>
              <option value="Korea, Republic of" data-alternative-spellings="KR South Korea" data-relevancy-booster="1.5">Korea, Republic of</option>
              <option value="Kuwait" data-alternative-spellings="KW الكويت">Kuwait</option>
              <option value="Kyrgyzstan" data-alternative-spellings="KG Кыргызстан">Kyrgyzstan</option>
              <option value="Lao People's Democratic Republic" data-alternative-spellings="LA">Lao People's Democratic Republic</option>
              <option value="Latvia" data-alternative-spellings="LV Latvija">Latvia</option>
              <option value="Lebanon" data-alternative-spellings="LB لبنان">Lebanon</option>
              <option value="Lesotho" data-alternative-spellings="LS">Lesotho</option>
              <option value="Liberia" data-alternative-spellings="LR">Liberia</option>
              <option value="Libyan Arab Jamahiriya" data-alternative-spellings="LY ليبيا">Libyan Arab Jamahiriya</option>
              <option value="Liechtenstein" data-alternative-spellings="LI">Liechtenstein</option>
              <option value="Lithuania" data-alternative-spellings="LT Lietuva">Lithuania</option>
              <option value="Luxembourg" data-alternative-spellings="LU">Luxembourg</option>
              <option value="Macao" data-alternative-spellings="MO">Macao</option>
              <option value="Macedonia, The Former Yugoslav Republic Of" data-alternative-spellings="MK Македонија">Macedonia, The Former Yugoslav Republic Of</option>
              <option value="Madagascar" data-alternative-spellings="MG Madagasikara">Madagascar</option>
              <option value="Malawi" data-alternative-spellings="MW">Malawi</option>
              <option value="Malaysia" data-alternative-spellings="MY">Malaysia</option>
              <option value="Maldives" data-alternative-spellings="MV">Maldives</option>
              <option value="Mali" data-alternative-spellings="ML">Mali</option>
              <option value="Malta" data-alternative-spellings="MT">Malta</option>
              <option value="Marshall Islands" data-alternative-spellings="MH" data-relevancy-booster="0.5">Marshall Islands</option>
              <option value="Martinique" data-alternative-spellings="MQ">Martinique</option>
              <option value="Mauritania" data-alternative-spellings="MR الموريتانية">Mauritania</option>
              <option value="Mauritius" data-alternative-spellings="MU">Mauritius</option>
              <option value="Mayotte" data-alternative-spellings="YT">Mayotte</option>
              <option value="Mexico" data-alternative-spellings="MX Mexicanos" data-relevancy-booster="1.5">Mexico</option>
              <option value="Micronesia, Federated States of" data-alternative-spellings="FM">Micronesia, Federated States of</option>
              <option value="Moldova, Republic of" data-alternative-spellings="MD">Moldova, Republic of</option>
              <option value="Monaco" data-alternative-spellings="MC">Monaco</option>
              <option value="Mongolia" data-alternative-spellings="MN Mongγol ulus Монгол улс">Mongolia</option>
              <option value="Montenegro" data-alternative-spellings="ME">Montenegro</option>
              <option value="Montserrat" data-alternative-spellings="MS" data-relevancy-booster="0.5">Montserrat</option>
              <option value="Morocco" data-alternative-spellings="MA المغرب">Morocco</option>
              <option value="Mozambique" data-alternative-spellings="MZ Moçambique">Mozambique</option>
              <option value="Myanmar" data-alternative-spellings="MM">Myanmar</option>
              <option value="Namibia" data-alternative-spellings="NA Namibië">Namibia</option>
              <option value="Nauru" data-alternative-spellings="NR Naoero" data-relevancy-booster="0.5">Nauru</option>
              <option value="Nepal" data-alternative-spellings="NP नेपाल">Nepal</option>
              <option value="Netherlands" data-alternative-spellings="NL Holland Nederland" data-relevancy-booster="1.5">Netherlands</option>
              <option value="New Caledonia" data-alternative-spellings="NC" data-relevancy-booster="0.5">New Caledonia</option>
              <option value="New Zealand" data-alternative-spellings="NZ Aotearoa">New Zealand</option>
              <option value="Nicaragua" data-alternative-spellings="NI">Nicaragua</option>
              <option value="Niger" data-alternative-spellings="NE Nijar">Niger</option>
              <option value="Nigeria" data-alternative-spellings="NG Nijeriya Naíjíríà" data-relevancy-booster="1.5">Nigeria</option>
              <option value="Niue" data-alternative-spellings="NU" data-relevancy-booster="0.5">Niue</option>
              <option value="Norfolk Island" data-alternative-spellings="NF" data-relevancy-booster="0.5">Norfolk Island</option>
              <option value="Northern Mariana Islands" data-alternative-spellings="MP" data-relevancy-booster="0.5">Northern Mariana Islands</option>
              <option value="Norway" data-alternative-spellings="NO Norge Noreg" data-relevancy-booster="1.5">Norway</option>
              <option value="Oman" data-alternative-spellings="OM عمان">Oman</option>
              <option value="Pakistan" data-alternative-spellings="PK پاکستان" data-relevancy-booster="2">Pakistan</option>
              <option value="Palau" data-alternative-spellings="PW" data-relevancy-booster="0.5">Palau</option>
              <option value="Palestinian Territory, Occupied" data-alternative-spellings="PS فلسطين">Palestinian Territory, Occupied</option>
              <option value="Panama" data-alternative-spellings="PA">Panama</option>
              <option value="Papua New Guinea" data-alternative-spellings="PG">Papua New Guinea</option>
              <option value="Paraguay" data-alternative-spellings="PY">Paraguay</option>
              <option value="Peru" data-alternative-spellings="PE">Peru</option>
              <option value="Philippines" data-alternative-spellings="PH Pilipinas" data-relevancy-booster="1.5">Philippines</option>
              <option value="Pitcairn" data-alternative-spellings="PN" data-relevancy-booster="0.5">Pitcairn</option>
              <option value="Poland" data-alternative-spellings="PL Polska" data-relevancy-booster="1.25">Poland</option>
              <option value="Portugal" data-alternative-spellings="PT Portuguesa" data-relevancy-booster="1.5">Portugal</option>
              <option value="Puerto Rico" data-alternative-spellings="PR">Puerto Rico</option>
              <option value="Qatar" data-alternative-spellings="QA قطر">Qatar</option>
              <option value="Réunion" data-alternative-spellings="RE Reunion">Réunion</option>
              <option value="Romania" data-alternative-spellings="RO Rumania Roumania România">Romania</option>
              <option value="Russian Federation" data-alternative-spellings="RU Rossiya Российская Россия" data-relevancy-booster="2.5">Russian Federation</option>
              <option value="Rwanda" data-alternative-spellings="RW">Rwanda</option>
              <option value="Saint Barthélemy" data-alternative-spellings="BL St. Barthelemy">Saint Barthélemy</option>
              <option value="Saint Helena" data-alternative-spellings="SH St.">Saint Helena</option>
              <option value="Saint Kitts and Nevis" data-alternative-spellings="KN St.">Saint Kitts and Nevis</option>
              <option value="Saint Lucia" data-alternative-spellings="LC St.">Saint Lucia</option>
              <option value="Saint Martin (French Part)" data-alternative-spellings="MF St.">Saint Martin (French Part)</option>
              <option value="Saint Pierre and Miquelon" data-alternative-spellings="PM St.">Saint Pierre and Miquelon</option>
              <option value="Saint Vincent and the Grenadines" data-alternative-spellings="VC St.">Saint Vincent and the Grenadines</option>
              <option value="Samoa" data-alternative-spellings="WS">Samoa</option>
              <option value="San Marino" data-alternative-spellings="SM">San Marino</option>
              <option value="Sao Tome and Principe" data-alternative-spellings="ST">Sao Tome and Principe</option>
              <option value="Saudi Arabia" data-alternative-spellings="SA السعودية">Saudi Arabia</option>
              <option value="Senegal" data-alternative-spellings="SN Sénégal">Senegal</option>
              <option value="Serbia" data-alternative-spellings="RS Србија Srbija">Serbia</option>
              <option value="Seychelles" data-alternative-spellings="SC" data-relevancy-booster="0.5">Seychelles</option>
              <option value="Sierra Leone" data-alternative-spellings="SL">Sierra Leone</option>
              <option value="Singapore" data-alternative-spellings="SG Singapura  சிங்கப்பூர் குடியரசு 新加坡共和国">Singapore</option>
              <option value="Sint Maarten (Dutch Part)" data-alternative-spellings="SX">Sint Maarten (Dutch Part)</option>
              <option value="Slovakia" data-alternative-spellings="SK Slovenská Slovensko">Slovakia</option>
              <option value="Slovenia" data-alternative-spellings="SI Slovenija">Slovenia</option>
              <option value="Solomon Islands" data-alternative-spellings="SB">Solomon Islands</option>
              <option value="Somalia" data-alternative-spellings="SO الصومال">Somalia</option>
              <option value="South Africa" data-alternative-spellings="ZA RSA Suid-Afrika">South Africa</option>
              <option value="South Georgia and the South Sandwich Islands" data-alternative-spellings="GS">South Georgia and the South Sandwich Islands</option>
              <option value="South Sudan" data-alternative-spellings="SS">South Sudan</option>
              <option value="Spain" data-alternative-spellings="ES España" data-relevancy-booster="2">Spain</option>
              <option value="Sri Lanka" data-alternative-spellings="LK ශ්‍රී ලංකා இலங்கை Ceylon">Sri Lanka</option>
              <option value="Sudan" data-alternative-spellings="SD السودان">Sudan</option>
              <option value="Suriname" data-alternative-spellings="SR शर्नम् Sarnam Sranangron">Suriname</option>
              <option value="Svalbard and Jan Mayen" data-alternative-spellings="SJ" data-relevancy-booster="0.5">Svalbard and Jan Mayen</option>
              <option value="Swaziland" data-alternative-spellings="SZ weSwatini Swatini Ngwane">Swaziland</option>
              <option value="Sweden" data-alternative-spellings="SE Sverige" data-relevancy-booster="1.5">Sweden</option>
              <option value="Switzerland" data-alternative-spellings="CH Swiss Confederation Schweiz Suisse Svizzera Svizra" data-relevancy-booster="1.5">Switzerland</option>
              <option value="Syrian Arab Republic" data-alternative-spellings="SY Syria سورية">Syrian Arab Republic</option>
              <option value="Taiwan, Province of China" data-alternative-spellings="TW 台灣 臺灣">Taiwan, Province of China</option>
              <option value="Tajikistan" data-alternative-spellings="TJ Тоҷикистон Toçikiston">Tajikistan</option>
              <option value="Tanzania, United Republic of" data-alternative-spellings="TZ">Tanzania, United Republic of</option>
              <option value="Thailand" data-alternative-spellings="TH ประเทศไทย Prathet Thai">Thailand</option>
              <option value="Timor-Leste" data-alternative-spellings="TL">Timor-Leste</option>
              <option value="Togo" data-alternative-spellings="TG Togolese">Togo</option>
              <option value="Tokelau" data-alternative-spellings="TK" data-relevancy-booster="0.5">Tokelau</option>
              <option value="Tonga" data-alternative-spellings="TO">Tonga</option>
              <option value="Trinidad and Tobago" data-alternative-spellings="TT">Trinidad and Tobago</option>
              <option value="Tunisia" data-alternative-spellings="TN تونس">Tunisia</option>
              <option value="Turkey" data-alternative-spellings="TR Türkiye Turkiye">Turkey</option>
              <option value="Turkmenistan" data-alternative-spellings="TM Türkmenistan">Turkmenistan</option>
              <option value="Turks and Caicos Islands" data-alternative-spellings="TC" data-relevancy-booster="0.5">Turks and Caicos Islands</option>
              <option value="Tuvalu" data-alternative-spellings="TV" data-relevancy-booster="0.5">Tuvalu</option>
              <option value="Uganda" data-alternative-spellings="UG">Uganda</option>
              <option value="Ukraine" data-alternative-spellings="UA Ukrayina Україна">Ukraine</option>
              <option value="United Arab Emirates" data-alternative-spellings="AE UAE الإمارات">United Arab Emirates</option>
              <option value="United Kingdom" data-alternative-spellings="GB Great Britain England UK Wales Scotland Northern Ireland" data-relevancy-booster="2.5">United Kingdom</option>
              <option value="United States" data-relevancy-booster="3.5" data-alternative-spellings="US USA United States of America">United States</option>
              <option value="United States Minor Outlying Islands" data-alternative-spellings="UM">United States Minor Outlying Islands</option>
              <option value="Uruguay" data-alternative-spellings="UY">Uruguay</option>
              <option value="Uzbekistan" data-alternative-spellings="UZ Ўзбекистон O'zbekstan O‘zbekiston">Uzbekistan</option>
              <option value="Vanuatu" data-alternative-spellings="VU">Vanuatu</option>
              <option value="Venezuela" data-alternative-spellings="VE">Venezuela</option>
              <option value="Vietnam" data-alternative-spellings="VN Việt Nam" data-relevancy-booster="1.5">Vietnam</option>
              <option value="Virgin Islands, British" data-alternative-spellings="VG" data-relevancy-booster="0.5">Virgin Islands, British</option>
              <option value="Virgin Islands, U.S." data-alternative-spellings="VI" data-relevancy-booster="0.5">Virgin Islands, U.S.</option>
              <option value="Wallis and Futuna" data-alternative-spellings="WF" data-relevancy-booster="0.5">Wallis and Futuna</option>
              <option value="Western Sahara" data-alternative-spellings="EH لصحراء الغربية">Western Sahara</option>
              <option value="Yemen" data-alternative-spellings="YE اليمن">Yemen</option>
              <option value="Zambia" data-alternative-spellings="ZM">Zambia</option>
              <option value="Zimbabwe" data-alternative-spellings="ZW">Zimbabwe</option>
            </select>
        </div>
    </fieldset>
    <h3>Company/organization</h3>
    <fieldset>
        <div class="profile-form-row">
            <div class="profile-form-label">Title </div>
            <input class="required" id="title" name="title" value="{$user/*:title/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Company/Organization </div>
            <input class="required" id="organization" name="organization" value="{$user/*:organization/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Size </div>
            <select class="required" id="companysize" name="companysize" data-initvalue="{$user/*:companysize/string()}" type="text">
	            <option>1-250</option>
	            <option>251-1000</option>
	            <option>1001-10,000</option>
	            <option>10,000+</option>
            </select>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Industry </div>
            <select class="required" id="industry" name="industry" data-initvalue="{$user/*:industry/string()}">
	            <option value="Aviation/Aerospace">Aviation/Aerospace</option>
	            <option value="Consulting">Consulting</option>
	            <option value="Consumer Packaged Goods">Consumer Packaged Goods</option>
	            <option value="Education">Education</option>
	            <option value="Energy">Energy</option>
	            <option value="Federal Government">Federal Government</option>
	            <option value="Financial Services">Financial Services</option>
	            <option value="Healthcare">Healthcare</option>
	            <option value="Insurance">Insurance</option>
	            <option value="Legal">Legal</option>
	            <option value="Life Sciences">Life Sciences</option>
	            <option value="Logistics/Transportation">Logistics/Transportation</option>
	            <option value="Manufacturing">Manufacturing</option>
	            <option value="Non-profit/Associations">Non-profit/Associations</option>
	            <option value="Publishing">Publishing</option>
	            <option value="Retail">Retail</option>
	            <option value="Services">Services</option>
	            <option value="State and Local Government">State and Local Government</option>
	            <option value="Technology">Technology</option>
	            <option value="Telecommunications">Telecommunications</option>
	            <option value="Travel/Entertainment">Travel/Entertainment</option>
            </select>
        </div>
    </fieldset>
    <!--
    <h3>Educational background</h3>
    <fieldset>
        <div class="profile-form-row">
            <div class="profile-form-label">School </div>
            <input class="" id="school" name="school" value="{$user/*:school/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Year of graduation </div>
            <select class="yearpicker" id="yog" name="yog" data-value="{$user/*:yog/string()}"></select>
        </div>
    </fieldset>
    -->
    </div>
  </xsl:template>

   <xsl:template match="reset-hidden-fields">
       <input id="token" name="token" value="$params[@name eq 'token']" type="hidden">
            <xsl:attribute name="value">
               <xsl:copy-of select="$params[@name eq  'token']"/>
            </xsl:attribute>
       </input>
       <input id="id" name="id" value="$params[@name eq 'id']" type="hidden">
            <xsl:attribute name="value">
               <xsl:copy-of select="$params[@name eq  'id']"/>
            </xsl:attribute>
       </input>
   </xsl:template>
   <xsl:template match="cornify">
    <xsl:if test="users:cornifyEnabled()">
        &#160;<a href="http://www.cornify.com" onclick="cornify_add();return false;">(cornify)</a>
    </xsl:if>
   </xsl:template>
    
   <xsl:template match="signup-form-hidden-fields">
      <input type="hidden" name="s_download" id="s_download">
         <xsl:attribute name="value"> 
            <xsl:value-of select="xdmp:get-request-field('d')"/>
         </xsl:attribute>
      </input>
      <input type="hidden" name="s_page" id="s_page">
         <xsl:attribute name="value"> 
            <xsl:value-of select="xdmp:get-request-field('p')"/>
         </xsl:attribute>
      </input>
   </xsl:template>

</xsl:stylesheet>
