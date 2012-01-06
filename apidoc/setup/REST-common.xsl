<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:xdmp="http://marklogic.com/xdmp"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs apidoc api xdmp">

  <xdmp:import-module href="/apidoc/model/data-access.xqy" namespace="http://marklogic.com/rundmc/api"/>

  <xsl:variable name="REST-lib" select="'manage'"/>

  <xsl:template mode="result-doc-path" match="apidoc:function[@lib eq $REST-lib]" name="REST-doc-uri">
    <xsl:param name="name" select="@name"/>
    <xsl:variable name="external-uri-translation-result">
      <xsl:call-template name="external-REST-doc-uri">
        <xsl:with-param name="name" select="$name"/>
      </xsl:call-template>
    </xsl:variable>
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
    <xsl:variable name="trailing-slash-stripped" select="replace($name, '/$', '')"/>    <!-- /manage/v1/ => /manage/v1  -->
    <xsl:variable name="braceless-alternatives"  select="replace($trailing-slash-stripped,
                                                                 '\{ ([^|]+) \| ([^}]+) \}',
                                                                 '\$$1-or-$2',
                                                                 'x')"/>                <!-- {foo|bar}   => $foo-or-bar -->
    <xsl:text>/REST</xsl:text>
    <xsl:value-of select="translate($braceless-alternatives,
                                    '{}',
                                    '$')"/>                                             <!-- /foo/{bar}  => /foo/$bar   -->
  </xsl:template>

</xsl:stylesheet>
