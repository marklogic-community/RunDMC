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
  xmlns:fn   ="http://www.w3.org/2005/xpath-functions"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="cts draft fn ml qp search so srv u users xdmp xs">

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

    <xsl:if test="@developer-license-page and @requirements-page">
      <ul class="info">
        <xsl:if test="@whats-new-page">
            <li><a href="{@whats-new-page}">What's New?&#160;»</a></li>
        </xsl:if>
        <xsl:if test="@developer-license-page">
            <li><a href="{@developer-license-page}">Read about the Developer license &#160;»</a></li>
        </xsl:if>
        <li><a href="{@requirements-page}">Review System Requirements&#160;»</a></li>
      </ul>
    </xsl:if>

    <div id="license-agreement-dialog" class="force-scrollbars" style="display: none;">
        <xsl:copy-of select="doc('/eula.xml')"/>
    </div>

    <div id="download-curl-dialog" style="display: none">

        <div class="download-url-label" >Please use the following, one-time-use URL to fetch the download:</div>
        <textarea readonly="readonly" class="download-url" id="curl-url"/>
        <button class="copy-button" id="copy-url-button"
                data-clipboard-target="curl-url" title="Click to copy">Copy to Clipboard</button>

        <div class="secure download-url-label" >Or use the secure version here instead:</div>
        <textarea readonly="readonly" class="secure download-url" id="secure-curl-url"/>
        <button class="secure copy-button" id="copy-secure-url-button"
                data-clipboard-target="secure-curl-url" title="Click to copy.">Copy to Clipboard</button>
    </div>

    <div class="download-confirmation" id="confirm-dialog" style="display: none">
        <p style="line-height: 140%">
        In order to download and use this MarkLogic software you are required to accept the <a class="license-popup" style="color: #01639D" href="#">MarkLogic Developer License Agreement</a> and install a license key.
        </p>

        <xsl:if test="empty(users:getCurrentUser())">
        <p>Sign in with your MarkLogic Community credentials or <a id="confirm-dialog-signup" style="color: #01639D" href="/people/signup">Sign up</a> for free:</p>
        </xsl:if>

        <div style="display: block" id="download-confirm-email">
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
               <input type="checkbox" id="iaccept" name="iaccept" value="true"/><label for="iaccept">&#160;&#160;I accept the terms in the <a style="color: #01639D;" href="#" class="license-popup" >MarkLogic Developer License Agreement</a>.</label>
           </div>
        </div>
    </div>


    <xsl:apply-templates mode="product-platform" select="platform"/>
    <xsl:apply-templates mode="maven" select="maven"/>
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

  <xsl:template mode="maven" match="maven">
    <section class="download">
        <h3>Maven</h3>
        <h4>Repository</h4>
        <textarea readonly="readonly" class="maven-frag"
  >&lt;repository&gt;
      &lt;id&gt;MarkLogic-releases&lt;/id&gt;
      &lt;name&gt;MarkLogic Releases&lt;/name&gt;
      &lt;url&gt;http://developer.marklogic.com/maven2&lt;/url&gt;
  &lt;/repository&gt;</textarea>
        <h4>Dependencies</h4>
        <xsl:apply-templates mode="maven" select="artifact"/>
    </section>
  </xsl:template>

  <xsl:template mode="maven" match="artifact">
      <textarea readonly="readonly" class="maven-frag"
>&lt;dependency&gt;
    &lt;groupId&gt;com.marklogic&lt;/groupId&gt;
    &lt;artifactId&gt;<xsl:value-of select="@id"/>&lt;/artifactId&gt;
    &lt;version&gt;<xsl:value-of select="@version"/>&lt;/version&gt;
&lt;/dependency&gt;</textarea>
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
      </th>
      <xsl:if test="$num-cols eq 3">
        <td>
          <xsl:apply-templates select="installer"/>
        </td>
      </xsl:if>
      <xsl:if test="$num-cols gt 1">
        <td>
          <xsl:value-of select="@size"/>&#160;&#160;
          <xsl:choose>
            <xsl:when test="@sha1">
              <input type="hidden" value="{@href}"/>
              <a href="data:text/plain;charset=US-ASCII,{@sha1}"
                onClick="$(this).attr('download', $(this).prev().attr('value').replace(/\/.*\//, '') + '.sha1');"
                title="Download SHA1"> (SHA1) </a>
            </xsl:when>
            <xsl:when test="@md5">
              <input type="hidden" value="{@href}"/>
              <a href="data:text/plain;charset=US-ASCII,{@md5}"
                onClick="$(this).attr('download', $(this).prev().attr('value').replace(/\/.*\//, '') + '.md5');"
                title="Download MD5"> (MD5) </a>
            </xsl:when>
          </xsl:choose>
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
                <br/><div class="doc-desc"><xsl:copy-of select="doc(base-uri(.))//*:description"/></div>
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
                <br/><div class="doc-desc"><p><xsl:value-of select="doc(base-uri(.))//*:description"/></p></div>
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
            <input disabled="disabled" readonly="readonly" required="required" class="email" id="email" name="email" value="{$user/*:email/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Full Name </div>
            <input autofocus="autofocus" class="required" required="required" id="name" name="name" value="{$user/*:name/string()}" type="text"/>
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
            <input class="phone" id="phone" name="phone" required="required" value="{$user/*:phone/string()}" type="text"/>
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
        <div class="profile-form-row">
            <div class="profile-form-label">Street </div>
            <input class="required" id="street" name="street" required="required" value="{$user/*:street/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">City </div>
            <input class="required" id="city" name="city" required="required" value="{$user/*:city/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">State </div>
            <input class="required" id="state" name="state" required="required" value="{$user/*:state/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Zip/Postal Code </div>
            <input class="required" id="zip" name="zip" required="required" value="{$user/*:zip/string()}" type="text"/>
        </div>
        -->
        <div class="profile-form-row">
            <div class="profile-form-label">Country </div>
            <select class="required countrypicker country" id="country" required="required" name="country" data-initvalue="{$user/*:country/string()}" autocorrect="off" autocomplete="off">
                <xsl:copy-of select="doc('/private/countries.xml')/*:select/*:option"/>
            </select>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Company/Organization </div>
            <input class="required" id="organization" name="organization" required="required" value="{$user/*:organization/string()}" type="text"/>
        </div>
        <div class="profile-form-row">
            <div class="profile-form-label">Industry </div>
            <select class="required" id="industry" name="industry" required="required" data-initvalue="{$user/*:industry/string()}">
          <option value="Aviation/Aerospace">Aviation/Aerospace</option>
      <option value="Commodity Trading">Commodity Trading</option>
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
      <option value="Mining/Construction/Engineering">Mining/Construction/Engineering</option>
          <option value="Non-profit/Associations">Non-profit/Associations</option>
          <option value="Other">Other</option>
          <option value="Publishing/Media">Publishing/Media</option>
          <option value="Retail">Retail</option>
          <option value="Services">Services</option>
          <option value="State and Local Government">State and Local Government</option>
          <option value="Technology">Technology</option>
          <option value="Technology - Hardware">Technology - Hardware</option>
          <option value="Technology - Software">Technology - Software</option>
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
    <xsl:if test="xdmp:get-request-field('d') and not(xdmp:get-request-field('d') eq '')">
      <input type="hidden" name="s_download" id="s_download">
        <xsl:attribute name="value">
          <xsl:value-of select="xdmp:get-request-field('d')"/>
        </xsl:attribute>
      </input>
    </xsl:if>
    <xsl:if test="xdmp:get-request-field('p') and not(xdmp:get-request-field('p') eq '')">
      <input type="hidden" name="s_page" id="s_page">
        <xsl:attribute name="value">
          <xsl:value-of select="xdmp:get-request-field('p')"/>
        </xsl:attribute>
      </input>
    </xsl:if>
    <input type="hidden" class="demandbase-hidden" name="dba_Company_Name__c" id="dba_Company_Name__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="TickerSymbol__c" id="TickerSymbol__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Sub_Industry__c" id="Sub_Industry__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Primary_SIC__c" id="Primary_SIC__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Revenue_Range__c" id="Revenue_Range__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="AnnualRevenue" id="AnnualRevenue" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Employee_Range__c" id="Employee_Range__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="NumberOfEmployees" id="NumberOfEmployees" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Address" id="Address" value=""  />
    <input type="hidden" class="demandbase-hidden" name="City" id="City" value=""  />
    <input type="hidden" class="demandbase-hidden" name="PostalCode" id="PostalCode" value=""  />
    <input type="hidden" class="demandbase-hidden" name="ISO2__c" id="ISO2__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Latitude" id="Latitude" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Longitude" id="Longitude" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Website" id="Website" value=""  />
    <input type="hidden" class="demandbase-hidden" name="traffic__c" id="traffic__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="b2b__c" id="b2b__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="b2c__c" id="b2c__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Fortune_1000__c" id="Fortune_1000__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Forbes_2000__c" id="Forbes_2000__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="demandbase_sid__c" id="demandbase_sid__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="demandbase_data_source__c" id="demandbase_data_source__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="Audience__c" id="Audience__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="audience_segment__c" id="audience_segment__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="demandbase_ip__c" id="demandbase_ip__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_company_name__c" id="registry_company_name__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_city__c" id="registry_city__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_state__c" id="registry_state__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_zip_code__c" id="registry_zip_code__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_area_code__c" id="registry_area_code__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_dma_code__c" id="registry_dma_code__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_country__c" id="registry_country__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_country_code__c" id="registry_country_code__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_country_code3__c" id="registry_country_code3__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_latitude__c" id="registry_latitude__c" value=""  />
    <input type="hidden" class="demandbase-hidden" name="registry_longitude__c" id="registry_longitude__c" value=""  />
  </xsl:template>

  <xsl:template match="countries">
    <xsl:copy-of select="doc('/private/countries.xml')/*:select/*:option"/>
  </xsl:template>

  <xsl:template match="entypo-attribution">
    <xsl:if test="base-uri($content) eq '/index.xml'">
      <span class="entypo-attribution">(Entypo pictograms by <a target="_blank" href="http://www.entypo.com">Daniel Bruce</a>)</span>
    </xsl:if>
  </xsl:template>

  <xsl:template match="open-graph">
    <meta property="og:title">
      <xsl:attribute name="content"><xsl:value-of select="u:get-page-title($content)"/></xsl:attribute>
    </meta>
    <meta property="og:description">
      <xsl:attribute name="content"><xsl:value-of select="u:get-page-description($content)"/></xsl:attribute>
    </meta>
    <meta property="og:url">
      <xsl:attribute name="content"><xsl:value-of select="u:get-full-url()"/></xsl:attribute>
    </meta>
  </xsl:template>

</xsl:stylesheet>
