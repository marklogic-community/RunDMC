<!-- This stylesheet converts from Disqus's data (JSON-translated-to-XML)
     to a more easily usable XML representation.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  xmlns:j="http://marklogic.com/xdmp/json"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:my="http://localhost"
  xmlns="http://marklogic.com/disqus"
  exclude-result-prefixes="my xs xsi j">

  <xsl:template match="/">
    <ml:Comments disqus_identifier="{(//j:entry[@key eq 'identifier'])[1]/j:value/j:array/j:value[1]}"
                 latest-update="{max(/j:object/j:entry[@key eq 'message'   ]/j:value/j:array/j:value
                                     /j:object/j:entry[@key eq 'created_at']/j:value)}">
      <!-- Comments that do not reply to another comment -->
      <xsl:variable name="top-level-comments"
                    select="/j:object/j:entry[@key eq 'message']
                            /j:value/j:array/j:value[not(string(j:object/j:entry[@key = 'parent_post']/j:value))]"/>
      <!-- Just process the top-level comments; replies to them will appear inside them -->
      <xsl:copy-of select="my:convert-comments($top-level-comments)"/>
    </ml:Comments>
  </xsl:template>

  <xsl:function name="my:convert-comments">
    <xsl:param name="comments"/>
    <!-- Sort comments so newest ones are listed first -->
    <xsl:apply-templates mode="process-comments" select="$comments">
      <xsl:sort select="j:object/j:entry[@key eq 'created_at']/j:value"
                order="descending"/>
    </xsl:apply-templates>
  </xsl:function>

  <!-- Create a <reply> element for each comment -->
  <xsl:template mode="process-comments" match="j:value">
    <xsl:variable name="this-id" select="j:object/j:entry[@key eq 'id']/j:value"/>
    <xsl:variable name="child-comments"
                  select="/j:object/j:entry[@key eq 'message']/j:value/j:array/j:value[$this-id eq j:object/j:entry[@key = 'parent_post']/j:value]"/>
    <reply>
      <xsl:apply-templates mode="convert-entries" select="j:object/j:entry"/>
      <!-- Nest the replies to this comment inside it -->
      <xsl:copy-of select="my:convert-comments($child-comments)"/>
    </reply>
  </xsl:template>

  <!-- Default conversion for entries -->
  <xsl:template mode="convert-entries" match="j:entry">
    <xsl:element name="{@key}">
      <xsl:apply-templates mode="convert-values" select="j:value"/>
    </xsl:element>
  </xsl:template>

  <!-- Default conversion for values (not graceful with multi-valued entries, of which I don't see any yet) -->
  <xsl:template mode="convert-values" match="j:value">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- Map values -->
  <xsl:template mode="convert-values" match="j:value[j:object]">
    <xsl:apply-templates mode="convert-entries" select="j:object/j:entry"/>
  </xsl:template>

  <!-- No need (at least currently) to dump all the thread and forum info; so strip these out -->
  <xsl:template mode="convert-entries" match="j:entry[@key eq 'thread'
                                                   or @key eq 'forum']"/>

</xsl:stylesheet>
