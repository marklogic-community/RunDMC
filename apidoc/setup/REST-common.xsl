<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:xdmp="http://marklogic.com/xdmp"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs apidoc api xdmp">

  <xsl:variable name="REST-libs" select="'manage','XXX'"/>

  <!-- This determines where each REST doc gets stored (at what document URI) -->
  <xsl:template mode="result-path-href" match="apidoc:function[@lib = $REST-libs]">
    <xsl:param name="fullname" select="api:REST-fullname(.)"/>

    <xsl:value-of select="api:REST-fullname-to-external-uri(
                            api:REST-fullname(.))"/>
  </xsl:template>


  <!-- Example input:  <function name="/v1/rest-apis/{name}" http-verb="GET"/>
       Example output: "/v1/rest-apis/[name] (GET)"
  -->
  <xsl:function name="api:REST-fullname">
    <xsl:param name="el"/>
    <xsl:sequence select="concat(api:translate-REST-resource-name($el/@name), ' (', ($el/@http-verb,'GET')[1], ')')"/>
  </xsl:function>

          <!-- E.g.,     "/v1/rest-apis/[name] (GET)"
                 ==> "GET /v1/rest-apis/[name]"
          -->
          <xsl:function name="api:REST-resource-heading">
            <xsl:param name="fullname"/>
            <xsl:sequence select="concat(api:verb-from-REST-fullname($fullname),
                                         ' ',
                                         api:reverse-translate-REST-resource-name(api:name-from-REST-fullname($fullname)))"/>
                                                                          <!--    api:name-from-REST-fullname($fullname)) "/>-->
          </xsl:function>

          <!-- E.g.,          "/v1/rest-apis/[name] (GET)"
                 ==> "/REST/GET/v1/rest-apis/*"
          -->
          <xsl:function name="api:REST-fullname-to-external-uri">
            <xsl:param name="fullname"/>
            <xsl:sequence select="concat('/REST/',
                                         api:verb-from-REST-fullname($fullname),
                                         api:REST-name-with-wildcards(
                                           api:name-from-REST-fullname($fullname)))"/>
          </xsl:function>

                  <!-- Wildcards (*) provide an easier, consistent way to guess the API doc page's URL.
                       E.g., /v1/rest-apis/[name]
                        ==>  /v1/rest-apis/*
                  -->
                  <xsl:function name="api:REST-name-with-wildcards">
                    <xsl:param name="resource-name"/>
                    <xsl:sequence select="replace($resource-name,
                                                  '\[ [^\]]+ \]',
                                                  '*',
                                                  'x')"/>
                  </xsl:function>

                  <!-- E.g., "/v1/rest-apis/[name] (GET)"
                                               ==> "GET"
                  -->
                  <xsl:function name="api:verb-from-REST-fullname">
                    <xsl:param name="fullname"/>
                     <xsl:sequence select="substring-before( substring-after( $fullname,' (' ), ')')"/>
                  </xsl:function>

                  <!-- E.g., "/v1/rest-apis/[name] (GET)"
                         ==> "/v1/rest-apis/[name]"
                  -->
                  <xsl:function name="api:name-from-REST-fullname">
                    <xsl:param name="fullname"/>
                    <xsl:sequence select="substring-before( $fullname,' (' )"/>
                  </xsl:function>

                  <xsl:function name="api:verb-sort-key-from-REST-fullname">
                    <xsl:param name="fullname"/>
                    <xsl:variable name="verb-list" select="'GET','POST','PUT','HEAD','DELETE'"/>
                    <xsl:variable name="verb" select="api:verb-from-REST-fullname($fullname)"/>
                    <xsl:sequence select="index-of($verb-list,$verb)"/>
                  </xsl:function>


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
                                       '\( ([^|)]+)  \|  \{ ([^}]+) \}  \)',
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

  <!-- This is intended to be temporary, with the idea that the docs themselves could migrate
       to using the square-brackets notation instead... -->
  <xsl:function name="api:reverse-translate-REST-resource-name">
    <xsl:param name="name"/>

    <!-- ASSUMPTION: Same assumption as above. Only these fixed patterns are supported. -->

    <!-- Step 1: convert back to this form: (default|{name}) -->
    <xsl:variable name="step1"
                  select="replace($name,
                                  &quot;\['  ([^']+)  '-or-  ([^\]]+)  \]&quot;,
                                                    '($1|{$2})',
                                  'x')"/>                                   <!-- ['default'-or-name] => (default|{name}) -->

    <!-- Step 2: convert back to the braced alternatives -->
    <xsl:variable name="step2"
                  select="replace($step1,
                                  '\[ ([^\]\-]+)  -or-  ([^\]]+) \]',
                                               '{$1|$2}',
                                  'x')"/>                                   <!--        [id-or-name] => {id|name}        -->

    <!-- Step 4: replace remaining brackets with braces -->
    <xsl:value-of select="translate($step2, '[]',
                                            '{}')"/>                        <!--              [name] => {name}           -->
  </xsl:function>

</xsl:stylesheet>
