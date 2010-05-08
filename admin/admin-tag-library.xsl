<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xmlns:label            ="http://developer.marklogic.com/site/internal/form/attribute-labels"
  xmlns:values           ="http://developer.marklogic.com/site/internal/form/values"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:variable name="staging-server" select="string($navigation/*/@staging-server)"/>

  <xsl:template match="admin-project-list
                     | admin-learn-list
                     | admin-post-list
                     | admin-announcement-list
                     | admin-event-list">
    <table>
      <thead>
        <tr>
          <th scope="col">Title</th>
          <th scope="col">Author</th>
          <th scope="col">Created</th>
          <th scope="col">Last&#160;Updated</th>
          <th scope="col">Status</th>
          <th class="last">&#160;</th>
        </tr>
      </thead>
      <tbody>
        <xsl:variable name="docs" select="if (self::admin-project-list)      then $ml:projects-by-name
                                     else if (self::admin-learn-list)        then ml:lookup-articles('','','')
                                     else if (self::admin-post-list)         then $ml:posts-by-date
                                     else if (self::admin-announcement-list) then $ml:announcements-by-date
                                     else if (self::admin-event-list)        then $ml:events-by-date
                                     else ()"/>
        <!--
        <xsl:variable name="docs" as="element()*">
          <xsl:apply-templates mode="docs-by-type" select="."/>
        </xsl:variable>
        -->
        <xsl:apply-templates mode="admin-listing" select="$docs">
          <xsl:with-param name="edit-path">
            <xsl:apply-templates mode="edit-path" select="."/>
          </xsl:with-param>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

          <!--
          <xsl:template mode="docs-by-type" match="admin-project-list">
            <xsl:sequence select="$ml:Projects"/>
          </xsl:template>

          <xsl:template mode="docs-by-type" match="admin-learn-list">
            <xsl:sequence select="$ml:Articles"/>
          </xsl:template>

          <xsl:template mode="docs-by-type" match="admin-post-list">
            <xsl:sequence select="$ml:posts-by-date"/>
          </xsl:template>

          <xsl:template mode="docs-by-type" match="admin-announcement-list">
            <xsl:sequence select="$ml:Announcements"/>
          </xsl:template>

          <xsl:template mode="docs-by-type" match="admin-event-list">
            <xsl:sequence select="$ml:Events"/>
          </xsl:template>
          -->


          <xsl:template mode="edit-path" match="admin-project-list"     >/code/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-learn-list"       >/learn/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-post-list"        >/blog/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-announcement-list">/news/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-event-list"       >/events/edit</xsl:template>


          <xsl:template mode="admin-listing" match="*">
            <xsl:param name="edit-path"/>
            <xsl:variable name="edit-link" select="concat($edit-path, '?path=', base-uri(.))"/>
            <tr>
              <xsl:if test="position() mod 2 eq 0">
                <xsl:attribute name="class">alt</xsl:attribute>
              </xsl:if>
              <th>
                <a href="{$edit-link}">
                  <xsl:value-of select="if (self::Project) then name else title"/>
                </a>
              </th>
              <td>
                <xsl:value-of select="if (self::Project) then contributors/contributor else author" separator=", "/>
              </td>
              <td>
                <xsl:value-of select="created"/>
              </td>

              <td>
                <xsl:value-of select="last-updated"/>
              </td>
              <xsl:variable name="effective-status" select="if (@status) then @status else 'Published'"/>
              <td class="status {lower-case($effective-status)}">
                <xsl:value-of select="$effective-status"/>
              </td>
              <td>
                <a href="{$edit-link}">Edit</a>
                <xsl:text>&#160;|&#160;</xsl:text>
                <!-- TODO: make preview work -->
                <a href="{$staging-server}{substring-before(base-uri(.), '.xml')}">Preview</a>
                <xsl:text>&#160;|&#160;</xsl:text>
                <!-- TODO: make publish/unpublish work -->
                <a href="#">
                  <xsl:choose>
                    <xsl:when test="@status eq 'Draft'">Publish</xsl:when>
                    <xsl:otherwise>Unpublish</xsl:otherwise>
                  </xsl:choose>
                </a>
                <!-- TODO: make remove work -->
                <!-- Leave out "Remove" for v1.0
                <xsl:text>&#160;|&#160;</xsl:text>
                <a href="#">Remove</a>
                -->
              </td>
            </tr>
          </xsl:template>


  <xsl:template match="admin-comment-list">
    <table id="tbl_comments">
      <caption>Comments</caption>
      <thead> 
        <tr>
          <th scope="col">Author</th>
          <th scope="col">Comment On</th>
          <th scope="col">Comment</th>

          <th scope="col">Posted Date</th>
          <th scope="col">Status</th>
          <th class="last">&#160;</th>
        </tr>
      </thead> 
      <tbody>
        <xsl:apply-templates mode="comment-listing" select="for $p in $ml:posts-by-date return ml:comments-for-post(base-uri($p))"/> 
      </tbody>
    </table>
  </xsl:template>

          <xsl:template mode="comment-listing" match="Comment">
            <xsl:variable name="post" select="doc(@about)/Post"/>
            <tr>            
              <xsl:if test="position() mod 2 eq 0">
                <xsl:attribute name="class">alt</xsl:attribute>
              </xsl:if>
              <th scope="row">
                <a href="{url}">
                  <xsl:value-of select="author"/>
                </a>
              </th>
              <td>
                <a href="/blog/edit?path={@about}" title="{substring($post/body, 1, 200)}..."> 
                  <xsl:value-of select="$post/title"/>
                </a>
              </td>
              <td>
                <xsl:value-of select="substring(body, 1, 100)"/>
                <xsl:text>...</xsl:text>
              </td>
              <td>
                <xsl:value-of select="created"/>
              </td>
              <xsl:variable name="status" select="if (@status eq 'Published') then 'Approved' else 'Pending'"/>
              <td class="status {lower-case($status)}">
                <xsl:value-of select="$status"/>
              </td>
              <td>
                <a href="/blog/comment-edit?path={base-uri(.)}">Edit</a>
                <xsl:text>&#160;|&#160;</xsl:text>

                <xsl:variable name="action" select="if (@status eq 'Published') then 'Revoke' else 'Approve'"/>
                <a href="/admin/approve-revoke-comment.xqy?path={base-uri(.)}&amp;action={$action}">
                  <xsl:value-of select="$action"/>
                </a>

                <xsl:text>&#160;|&#160;</xsl:text>
                <a href="javascript:if (confirm('Are you sure you want to delete this comment?')) {{ window.location = '/admin/delete-comment.xqy?path={base-uri(.)}'; }}">Remove</a>
              </td>
            </tr>            
          </xsl:template>

</xsl:stylesheet>
