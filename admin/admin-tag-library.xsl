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


  <xsl:template match="ml:post-list">
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
        <xsl:apply-templates mode="blog-post-listing" select="$ml:posts-by-date"/>
      </tbody>
    </table>
  </xsl:template>

          <xsl:template mode="blog-post-listing" match="Post">
            <xsl:variable name="edit-link" select="concat('/blog/edit?path=', base-uri(.))"/>
            <tr>
              <xsl:if test="position() mod 2 eq 0">
                <xsl:attribute name="class">alt</xsl:attribute>
              </xsl:if>
              <th>
                <a href="{$edit-link}">
                  <xsl:value-of select="title"/>
                </a>
              </th>
              <td>
                <xsl:value-of select="author"/>
              </td>
              <td>
                <xsl:value-of select="created"/>
              </td>

              <td>
                <xsl:value-of select="last-updated"/>
              </td>
              <td class="status {lower-case(@status)}">
                <xsl:value-of select="@status"/>
              </td>
              <td>
                <a href="{$edit-link}">Edit</a>
                <xsl:text> | </xsl:text>
                <!-- TODO: make preview work -->
                <a href="#">Preview</a>
                <xsl:text> | </xsl:text>
                <!-- TODO: make publish/unpublish work -->
                <a href="#">
                  <xsl:choose>
                    <xsl:when test="@status eq 'Published'">Unpublish</xsl:when>
                    <xsl:otherwise>Publish</xsl:otherwise>
                  </xsl:choose>
                </a>
                <!-- TODO: make remove work -->
                <xsl:text> | </xsl:text>
                <a href="#">Remove</a>
              </td>
            </tr>
          </xsl:template>

  <xsl:template match="ml:comment-list">
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
                <xsl:text> | </xsl:text>
                <!-- TODO: Make approve/revoke work -->
                <a href="#">
                  <xsl:value-of select="if (@status eq 'Published') then 'Revoke' else 'Approve'"/>
                </a>
                <xsl:text> | </xsl:text>
                <!-- TODO: Make remove work -->
                <a href="#">Remove</a></td>
            </tr>            
          </xsl:template>

</xsl:stylesheet>
