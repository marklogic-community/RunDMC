<!-- This stylesheet configures which page types have comments enabled and
     is concerned with generating the JS embed code for Disqus comments.
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
  xmlns:srv  ="http://marklogic.com/rundmc/server-urls"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="qp xs ml xdmp dq srv">


  <xsl:variable name="site-url-for-disqus" select="'http://developer.marklogic.com'"/>

  <!-- Disable comments on pages that explicitly disable them. Also disable comments in the standalone apidoc app -->
  <xsl:template mode="comment-section" match="*[@disable-comments or $srv:viewing-standalone-api]"/>

  <!-- Overridden by apidoc's XSLT -->
  <xsl:function name="ml:uri-for-commenting-purposes" as="xs:string">
    <xsl:param name="node"/>
    <!-- Normally, we just use the document URI -->
    <xsl:sequence select="base-uri($node)"/>
  </xsl:function>

  <!-- But allow comments everywhere else -->
  <xsl:template mode="comment-section" match="*">

    <div id="comments">
      <div>
        <section>
          <h2>Comments <img src="/images/i_speechbubble.png" alt="" width="30" height="28"/></h2>

          <xsl:apply-templates mode="comment-count" select="."/>

          <a id="post_comment"/>
          <!-- This will get replaced in the browser by Disqus's widget -->
          <div id="disqus_thread">
            <div id="dsq-content">
              <ul id="dsq-comments">
                <xsl:apply-templates select="ml:comments-for-doc-uri(ml:uri-for-commenting-purposes(.))/dq:reply"/>
              </ul>
            </div>
          </div>

          <!-- See http://docs.disqus.com/developers/universal/ -->
          <script type="text/javascript">
              var disqus_shortname = '<xsl:value-of select="$dq:shortname"/>';

              var disqus_developer = <xsl:value-of select="$dq:developer_0_or_1"/>;

              // The following are highly recommended additional parameters. Remove the slashes in front to use.
              var disqus_identifier = '<xsl:value-of select="ml:disqus-identifier(ml:uri-for-commenting-purposes(.))"/>';
              var disqus_url = '<xsl:value-of select="$site-url-for-disqus"/><xsl:value-of select="ml:external-uri(.)"/>';

              function disqus_config() {
                  this.callbacks.onNewComment = [function() { setTimeout(
                                                                function(){ $.ajax({ type: "POST",
                                                                                     url: "/updateDisqusThreads" });},
                                                                10000); } ];
                                                                <!-- It takes a while before the API makes it available -->
                                                                <!-- No sweat if this doesn't get called, as the scheduled
                                                                     task will pick it up. -->
              }

              (function() {
                  if (!disqus_shortname) return;
                  var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
                  dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
                  (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
              })();
          </script>
          <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
        </section>
      </div>
    </div>
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
        <xsl:value-of select="dq:message"/>
      </div>
      <!-- Nested replies -->
      <xsl:if test="dq:reply">
        <ul>
          <xsl:apply-templates select="dq:reply"/>
        </ul>
      </xsl:if>
    </li>
  </xsl:template>


  <!-- This rule renders the "Post a comment" link and comment count we see at the bottom
       of each blog post (including on the main /blog page) as well as any other page that has . It could be reused for other
       page types if we saw a need for it. But right now, blog posts are the only things
       that we display in paginated groups this way.
  -->
  <xsl:template mode="comment-count" match="*">
    <div class="action">
      <ul>
        <li>
          <!-- This will get replaced by the actual comment count from Disqus, as described here: http://docs.disqus.com/developers/universal/#comment-count -->
          <a href="#disqus_thread"
             data-disqus-identifier="{ml:disqus-identifier(
                                     ml:uri-for-commenting-purposes(.))}">
            <xsl:value-of select="count(
                                  ml:comments-for-doc-uri(
                                  ml:uri-for-commenting-purposes(.))//dq:reply)"/>
            comments<xsl:text/>
          </a>
        </li>
        <li>
          <a rel="nofollow" href="#post_comment">Post a comment</a>
        </li>
      </ul>
    </div>
    <!-- Source http://docs.disqus.com/developers/universal/#comment-count
    -->
    <script type="text/javascript">
        var disqus_shortname = '<xsl:value-of select="$dq:shortname"/>';

        (function () {
            if (!disqus_shortname) return;
            var s = document.createElement('script');
            s.async = true;
            s.type = 'text/javascript';
            s.src = '//' + disqus_shortname + '.disqus.com/count.js';
            (document.getElementsByTagName('HEAD')[0]
             ||document.getElementsByTagName('BODY')[0]).appendChild(s);
        }());
    </script>
  </xsl:template>

</xsl:stylesheet>
