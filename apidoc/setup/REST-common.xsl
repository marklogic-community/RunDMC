<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:fixup="http://marklogic.com/rundmc/api/fixup"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs apidoc api xdmp fixup">

  <xsl:import href="fixup.xsl"/>

  <xdmp:import-module href="/apidoc/model/data-access.xqy" namespace="http://marklogic.com/rundmc/api"/>

  <xsl:variable name="REST-libs" select="'manage','XXX'"/>

  <xsl:template mode="result-doc-path" match="apidoc:function[@lib = $REST-libs]" name="REST-doc-uri">
    <xsl:param name="name" select="fixup:fullname(.)"/>
    <xsl:message>Translating REST doc URI from <xsl:value-of select="@name"/>:</xsl:message>
    <xsl:variable name="external-uri-translation-result">
      <xsl:call-template name="external-REST-doc-uri">
        <xsl:with-param name="name" select="$name"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:message>To <xsl:value-of select="$external-uri-translation-result"/></xsl:message>
    <xsl:sequence select="translate($external-uri-translation-result,
                                    '?',
                                    $api:REST-uri-questionmark-substitute)"/>           <!-- ?foo=bar    => @foo=bar    -->
  </xsl:template>


  <!-- E.g. /manage/v1/servers/{id|name}/{custom}?group-id={id|name}
         => /manage/v1/servers/$id-or-name/$custom?group-id=$id-or-name

       Also: /manage/v1/
          => /manage/v1
  -->
  <xsl:template name="external-REST-doc-uri">
    <xsl:param name="name"/>
    <xsl:text>/REST</xsl:text>
    <xsl:value-of select="api:translate-REST-resource-name($name)"/>
  </xsl:template>

  <xsl:function name="api:translate-REST-resource-name">
    <xsl:param name="name"/>

    <!-- ASSUMPTION: The examples to the right, other than the letters used, are the
                     only fixed patterns supported here. A new pattern (such as
                     more than two "|" alternatives, or alternatives in a different order)
                     would require a code update here. -->

    <!-- Step 1: strip trailing slash -->
    <xsl:variable name="step1"
                  select="replace($name, '/$', '')"/>                       <!--      /manage/v1/ => /manage/v1          -->

    <!-- Step 2: handle the special parenthesized alternatives
                 pattern of this form: (default|{name}) -->
    <xsl:variable name="step2"
                  select="replace($step1,
                                       '\( ([^|)]+)  \|  \{ ([^}]+) \}  \)     ',
                                          &quot;['$1'-or-$2]&quot;,
                                  'x')"/>                                   <!-- (default|{name}) => ['default'-or-name] -->

    <!-- Step 3: handle the braced alternatives -->
    <xsl:variable name="step3"
                  select="replace($step2,
                                  '\{ ([^|}]+)  \|  ([^}]+) \}',
                                           '[$1-or-$2]',
                                  'x')"/>                                   <!--        {id|name} => [id-or-name]        -->

    <!-- Step 4: replace remaining brackets with square brackets -->
    <xsl:value-of select="translate($step3, '{}()',
                                            '[][]')"/>                      <!--           {name} => [name]              -->
                                                                            <!--           (name) => [name]              -->
  </xsl:function>


  <xsl:function name="api:display-REST-resource">
    <xsl:param name="fullname"/>

    <xsl:variable name="verb" select="tokenize($fullname,'/')[2]"/>

    <!-- e.g., /GET/foo/{bar} => /foo/{bar} -->
    <xsl:variable name="raw-uri" select="substring-after($fullname,$verb)"/>

    <!-- e.g., /foo/{bar} => /foo/[bar] -->
    <xsl:variable name="display-uri" select="api:translate-REST-resource-name($raw-uri)"/>

    <xsl:sequence select="concat($display-uri,' (',$verb,')')"/>
  </xsl:function>

</xsl:stylesheet>
