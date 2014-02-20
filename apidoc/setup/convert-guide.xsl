<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:my="http://localhost"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs raw my ml">

  <xsl:import href="../view/page.xsl"/>

  <xdmp:import-module href="/apidoc/setup/raw-docs-access.xqy" namespace="http://marklogic.com/rundmc/raw-docs-access"/>

  <xsl:output indent="no"/>

  <xsl:variable name="DEBUG_GROUPING" select="$convert-at-render-time"/>

  <xsl:param name="output-uri" select="raw:target-guide-doc-uri(.)"/>

  <xsl:template match="/">
    <!-- Strip out unhelpful list containers -->
    <xsl:variable name="useless-distinctions-stripped">
      <xsl:apply-templates mode="remove-useless-distinctions" select="."/>
    </xsl:variable>
    <!-- Capture section hierarchy -->
    <xsl:variable name="sections-captured">
      <xsl:apply-templates mode="capture-sections" select="$useless-distinctions-stripped"/>
    </xsl:variable>
    <!-- Capture list hierarchy -->
    <xsl:variable name="lists-captured">
      <xsl:apply-templates mode="capture-lists" select="$sections-captured"/>
    </xsl:variable>
    <!-- Merge adjacent Code samples -->
    <xsl:variable name="code-merged">
      <xsl:apply-templates mode="merge-code-examples" select="$lists-captured"/>
    </xsl:variable>
    <!-- Main conversion of source elements to XHTML elements -->
    <xsl:variable name="converted-content">
      <!-- Only copy the XML content for chapters; guides just have some metadata (copied later below) -->
      <xsl:apply-templates select="$code-merged/chapter/XML"/>
    </xsl:variable>
    <!-- We're reading from a doc in one database and writing to a doc in a different database, using a similar URI -->
    <xsl:message>Outputting converted guide to: <xsl:value-of select="$output-uri"/></xsl:message>
    <xsl:result-document href="{$output-uri}">
      <xsl:for-each select="/guide | /chapter">
        <xsl:copy>
          <xsl:apply-templates select="@*"/>
          <xsl:copy-of select="guide-title | title"/>
          <xsl:apply-templates mode="guide-metadata" select="."/>
          <xsl:copy-of select="chapter-list"/>
          <!-- Last step: add the XHTML namespace -->
          <xsl:apply-templates mode="add-xhtml-namespace" select="$converted-content"/>
        </xsl:copy>
      </xsl:for-each>
    </xsl:result-document>
    <xsl:if test="$DEBUG_GROUPING">
      <xsl:value-of select="xdmp:document-insert(concat('/DEBUG/sections-captured',$output-uri), $sections-captured)"/>
      <xsl:value-of select="xdmp:document-insert(concat('/DEBUG/lists-captured'   ,$output-uri),    $lists-captured)"/>
      <xsl:value-of select="xdmp:document-insert(concat('/DEBUG/code-merged'      ,$output-uri),    $code-merged)"/>
    </xsl:if>
  </xsl:template>

          <xsl:template mode="guide-metadata" match="chapter"/>
          <xsl:template mode="guide-metadata" match="guide">
            <!-- metadata from title.xml -->
            <info>
              <version>
                <xsl:value-of select="XML/Version"/>
              </version>
              <date>
                <xsl:value-of select="XML/Date"/>
              </date>
              <revision>
                <xsl:value-of select="XML/DateRev"/>
              </revision>
            </info>
          </xsl:template>


          <xsl:template mode="remove-useless-distinctions" match="@* | node()">
            <xsl:copy>
              <xsl:apply-templates mode="#current" select="@* | node()"/>
            </xsl:copy>
          </xsl:template>

          <!-- These container elements apparently add no value for list detection (they appear inconsistently) -->
          <xsl:template mode="remove-useless-distinctions" match="NumberList | NumberAList | WarningList">
            <xsl:apply-templates mode="#current"/>
          </xsl:template>

          <!-- Rewrite <Number1> tags to <Number> -->
          <xsl:template mode="remove-useless-distinctions" match="Number1">
            <Number>
              <xsl:apply-templates mode="#current"/>
            </Number>
          </xsl:template>

          <!-- Rewrite <NumberA1> tags to <NumberA> -->
          <xsl:template mode="remove-useless-distinctions" match="NumberA1">
            <NumberA>
              <xsl:apply-templates mode="#current"/>
            </NumberA>
          </xsl:template>


          <xsl:template mode="add-xhtml-namespace" match="@* | node()">
            <xsl:copy/>
          </xsl:template>

          <xsl:template mode="add-xhtml-namespace" match="*" priority="1">
            <xsl:element name="{local-name(.)}" namespace="http://www.w3.org/1999/xhtml">
              <xsl:apply-templates mode="#current" select="@* | node()"/>
            </xsl:element>
          </xsl:template>


  <!-- Don't need this attribute at this stage; only used to 
       resolve URIs of images being copied over -->
  <xsl:template match="/*/@original-dir"/>

  <xsl:template match="pagenum | TITLE"/>

  <!-- Heading-2MESSAGE case (priority should be greater 
       than Heading-* case) -->
  <xsl:template match="Heading-2MESSAGE" priority="1">
	  <xsl:variable name="heading-level" 
		  select="3"/>
	  <xsl:variable name="id">
		  <xsl:value-of select="normalize-space(.)"/> 
	  </xsl:variable>
    <!-- Beware of changing this structure without updating 
	 mode="guide-toc" (in toc.xsl), which depends on it -->
    <a id="{$id}"/>
    <xsl:element name="h{$heading-level}">
      <a href="#{$id}" class="sectionLink">
        <xsl:value-of select="normalize-space(.)"/>
      </a>
    </xsl:element>
  </xsl:template>

  <!-- Heading-* (except MESSAGE) case -->
  <xsl:template match="*[starts-with(local-name(.),'Heading-')]">
	  <xsl:variable name="heading-level" 
		  select="1 + number(substring-after(local-name(.),'-'))"/>
    <xsl:variable name="id">
      <xsl:apply-templates mode="heading-anchor-id" select="."/>
    </xsl:variable>
    <!-- Beware of changing this structure without updating 
	 mode="guide-toc" (in toc.xsl), which depends on it -->
    <a id="{$id}"/>
    <xsl:element name="h{$heading-level}">
      <a href="#{$id}" class="sectionLink">
        <xsl:value-of select="normalize-space(.)"/>
      </a>
    </xsl:element>
  </xsl:template>

  <!-- Cause and Response headings for messages guide -->
  <xsl:template match="Simple-Heading-3">
    <xsl:element name="h4">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:element>
  </xsl:template>

          <!-- Use only the last A/@ID inside the heading, since all links get rewritten to the last one -->
          <xsl:template mode="heading-anchor-id" match="*">
            <xsl:value-of select="my:full-anchor-id(A[@ID][last()]/@ID)"/>
          </xsl:template>

          <!-- Top-level anchor ID is simply "chapter" -->
          <xsl:template mode="heading-anchor-id" match="Heading-1">
            <xsl:text>chapter</xsl:text>
            <!--
            <xsl:value-of select="my:anchor-id-for-top-level-heading(.)"/>
            -->
          </xsl:template>

                  <xsl:function name="my:anchor-id-for-top-level-heading">
                    <xsl:param name="heading-1" as="element(Heading-1)"/>
                    <xsl:sequence select="my:basename-stem($heading-1/ancestor::XML/@original-file)"/>
                  </xsl:function>

                          <xsl:function name="my:basename-stem">
                            <xsl:param name="url"/>
                            <xsl:sequence select="substring-before(my:basename($url),'.xml')"/>
                          </xsl:function>

                                  <xsl:function name="my:basename">
                                    <xsl:param name="url"/>
                                    <xsl:sequence select="tokenize($url,'/')[last()]"/>
                                  </xsl:function>


  <xsl:template match="IMAGE">
    <img src="{@href}"/>
  </xsl:template>

  <!-- By default, do *not* copy elements -->
  <xsl:template match="*">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Copy these elements (and attributes too) -->
  <xsl:template match="@* | div | ul | ol | li | code">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="underline">
    <span class="underline">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- These lists are already well-structured and don't need to be captured -->
  <xsl:template match="BulletedList">
    <ul>
      <xsl:apply-templates select="Bulleted"/>
    </ul>
  </xsl:template>

          <xsl:template match="Bulleted">
            <li>
              <xsl:apply-templates/>
            </li>
          </xsl:template>

  <!-- Convert elements that should be converted -->
  <xsl:template match="*[string(my:new-name(.))]">
    <xsl:element name="{my:new-name(.)}">
      <xsl:apply-templates mode="desired-atts" select="@*"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

          <!-- We're not interested in the attributes of translated elements... -->
          <xsl:template mode="desired-atts" match="@*"/>

          <!-- ...except for these -->
          <xsl:template mode="desired-atts" match="@ROWSPAN[. ne '1']
                                                 | @COLSPAN[. ne '1']">
            <xsl:attribute name="{lower-case(name(.))}" select="."/>
          </xsl:template>


          <xsl:function name="my:new-name">
            <xsl:param name="element"/>
            <xsl:apply-templates mode="new-name" select="$element"/>
          </xsl:function>

                  <!-- Some need to be set to lower-case -->
                  <xsl:template mode="new-name" match="TABLE | TH">
                    <xsl:value-of select="lower-case(local-name(.))"/>
                  </xsl:template>
                  <!-- Others need to be renamed -->
                  <xsl:template mode="new-name" match="ROW"     >tr</xsl:template>
                  <xsl:template mode="new-name" match="CELL"    >td</xsl:template>
                  <xsl:template mode="new-name" match="Emphasis">em</xsl:template>
                  <xsl:template mode="new-name" match="Bold"    >strong</xsl:template>
                  <xsl:template mode="new-name" match="Code
                                                     | CodeLeft
                                                     | CodeNoIndent">pre</xsl:template>
                  <xsl:template mode="new-name" match="Body
                                                     | CellBody
                                                     | Body-indent
                                                     | Body-indent-blockquote">p</xsl:template>

                  <!-- By default, we just strip the start & end tags out -->
                  <xsl:template mode="new-name" match="*"/>


  <xsl:template match="Note">
    <p class="note">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- we add this wrapper when capturing lists (see below) -->
  <xsl:template match="NoteWithList">
    <div class="note">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

          <xsl:template match="NoteWithList/Note">
            <p>
              <xsl:apply-templates/>
            </p>
          </xsl:template>

  <xsl:template match="Warning">
    <p class="warning">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- Don't convert a single Body or CellBody child inside a CELL to a <p>; just process contents -->
  <xsl:template match="CELL[count(*) eq 1]/Body
                     | CELL[count(*) eq 1]/CellBody" priority="1">
    <xsl:apply-templates/>
  </xsl:template>


  <!-- The docapp code strips leading line breaks (and any preceding space) from each text node. Let's try that... -->
  <xsl:template match="text()">
    <xsl:value-of select="replace(., '^\s*\n', '')"/>
  </xsl:template>

  <!-- Now that we're merging adjacent <Code> elements, let's be more discriminating about
       which whitespace characters we strip. In particular, preserve the whitespace that
       comes at the beginning of a merged Code element (see below) -->
  <xsl:template match="text()[preceding-sibling::*[1][self::PRESERVE_FOLLOWING_WHITESPACE]]">
    <xsl:value-of select="."/>
  </xsl:template>

          <!--
          <!- - TODO: identify significant line breaks, e.g., in code examples, and modify rule(s) accordingly - ->
          <!- - Strip out line breaks - ->
          <xsl:template match="text()[not(ancestor::Code)]">
            <xsl:value-of select="replace(.,'&#xA;','')"/>
          </xsl:template>
          <!- - Strip out isolated line breaks in Code elements - ->
          <xsl:template match="Code/text()[not(normalize-space(.))]"/>
          -->


  <!-- Since we rewrite all links to point to the last anchor, it's safe to remove all the anchors that aren't last. -->
  <xsl:template match="A[@ID][not(position() eq last())]"/>

  <xsl:template match="A">
    <a>
      <xsl:apply-templates select="@ID | @href"/>
      <xsl:apply-templates mode="guide-link-content" select="."/>
    </a>
  </xsl:template>

 <!-- Remove apostrophe delimiters when present (assumption is they are the 
       first and last character in the string) and remove 'on page' -->
	  <xsl:template mode="guide-link-content" 
		  match='A[starts-with(normalize-space(.), "&apos;")]'
		  priority='1'>
		  <xsl:variable name="nopage" select="substring-before(
			  normalize-space(.), ' on page')"/>
		  <xsl:value-of select="substring($nopage,  2, 
			  string-length($nopage) - 2)"/>
          </xsl:template>

          <!-- Remove "on page 32" verbiage (if there is no apos) -->
	  <xsl:template mode="guide-link-content" 
		  match="A[contains(normalize-space(.), ' on page')]" >
		  <xsl:value-of select="substring-before(normalize-space(.), 
			  ' on page')"/>
          </xsl:template>

          <xsl:template mode="guide-link-content" match="A">
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:template>


          <xsl:template match="A/@ID">
            <xsl:attribute name="id" select="my:full-anchor-id(.)"/>
          </xsl:template>

                  <xsl:function name="my:full-anchor-id">
                    <xsl:param name="ID-att"/>
                    <xsl:sequence select="concat('id_',$ID-att)"/>
                    <!--
                    <xsl:sequence select="concat(my:anchor-id-for-top-level-heading($ID-att/ancestor::XML/div/Heading-1),'_',$ID-att)"/>
                    -->
                  </xsl:function>



          <!-- Links within the same chapter -->
          <xsl:template match="A/@href[contains(.,'#id(')][starts-with(.,my:basename(base-uri(.)))]" priority="2">
          <!--
          <xsl:template match="A/@href[contains(.,'#id(')][starts-with(.,)]" priority="2">
          -->
            <xsl:variable name="target-doc" select="root(.)"/>
            <xsl:attribute name="href" select="concat('#', my:anchor-id-from-href(.,$target-doc))"/>
          </xsl:template>

          <!-- Links to other chapters (whether the same or a different guide) -->
          <xsl:template match="A/@href[contains(.,'#id(')]" priority="1">
          <!--
          <xsl:template match="A/@href[starts-with(.,'../')]" priority="2">
          -->
            <xsl:variable name="target-doc" select="$raw:guide-docs[starts-with(my:fully-resolved-href(current()), */XML/@original-file)]"/>
            <xsl:if test="not($target-doc)">
              <xsl:message>BAD LINK FOUND! Unable to find referenced title or chapter doc for this link: <xsl:value-of select="."/></xsl:message>
            </xsl:if>
            <xsl:attribute name="href" select="concat(my:guide-doc-url($target-doc), '#', my:anchor-id-from-href(.,$target-doc))"/>
          </xsl:template>

                  <xsl:function name="my:guide-doc-url">
                    <xsl:param name="guide" as="document-node()?"/> <!-- if absent, then it's a bad link, and we'll get the warning above -->
                    <xsl:sequence select="$guide/ml:external-uri-for-string(raw:target-guide-doc-uri(.))"/>
                  </xsl:function>

                          <xsl:function name="my:fully-resolved-href">
                            <xsl:param name="href" as="attribute(href)"/>
                            <xsl:sequence select="resolve-uri($href, $href/ancestor::XML/@original-file)"/>
                          </xsl:function>

                  <xsl:function name="my:anchor-id-from-href" as="xs:string?">
                    <xsl:param name="href" as="attribute(href)"/>
                    <xsl:param name="target-doc" as="document-node()?"/>
                    <xsl:variable name="resolved-href" select="my:fully-resolved-href($href)"/>
                    <xsl:variable name="is-top-level-section-link" select="$resolved-href = $fully-resolved-top-level-heading-references"/>

                    <xsl:value-of>
                      <!-- The section name of the guide -->
                      <!--
                      <xsl:value-of select="my:basename-stem($href)"/>
                      -->
                      <!-- Leave out the _12345 part if we're linking to a top-level section -->
                      <xsl:if test="not($is-top-level-section-link)">
                        <xsl:variable name="id" select="my:extract-id-from-href($href)"/>
                        <!--
                        <xsl:variable name="section" select="$target-doc/guide/XML[starts-with($resolved-href,@original-file)]"/>
                        -->
                        <!-- Always rewrite to the last ID that appears, so we have a canonical one we can script against in the TOC (which also uses the last one present) -->
                        <xsl:variable name="canonical-fragment-id" select="$target-doc//*[A/@ID=$id]/A[@ID][last()]/@ID"/>
                        <xsl:value-of select="concat('id_', $canonical-fragment-id)"/>
                      </xsl:if>
                    </xsl:value-of>
                  </xsl:function>

                          <xsl:function name="my:extract-id-from-href">
                            <xsl:param name="href" as="xs:string"/>
                            <xsl:sequence select="substring-before(substring-after($href,'#id('),')')"/>
                          </xsl:function>

                          <xsl:variable name="fully-resolved-top-level-heading-references" as="xs:string*"
				  select="$raw:guide-docs/chapter/XML/Heading-1/A/@ID/concat(ancestor::XML/@original-file,'#id(',.,')')"/>


			  <!-- Fixup Linkerator links
			       Change "#display.xqy&function=" to "/"
			       -->
          <xsl:template match="A/@href[starts-with(.,'#display.xqy?function=')]" priority="3">
            <xsl:variable name="target-doc" select="$raw:guide-docs[starts-with(my:fully-resolved-href(current()), */XML/@original-file)]"/>
            <xsl:if test="not($target-doc)">
              <xsl:message>BAD LINK FOUND! Unable to find referenced title or chapter doc for this link: <xsl:value-of select="."/></xsl:message>
            </xsl:if>
	    <xsl:attribute name="href" 
		    select="concat('/', 
		    substring-after(., '#display.xqy?function='))"/>
    </xsl:template>
    <!-- End Linkerator fixup -->


  <xsl:template match="Hyperlink">
    <xsl:apply-templates/>
  </xsl:template>


  <xsl:template mode="capture-sections" match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:apply-templates mode="capture-sections-content" select="."/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="capture-sections-content" match="*">
     <xsl:apply-templates mode="capture-sections"/>
  </xsl:template>

  <xsl:template mode="capture-sections-content" match="XML">
     <xsl:call-template name="capture-sections"/>
  </xsl:template>

  <xsl:template name="capture-sections">
     <xsl:param name="current-level" select="1"/>
     <!-- Initially, group the children -->
     <xsl:param name="current-group" select="node()"/>
     <!-- Each heading starts a new group -->
     <xsl:variable name="current-heading" select="concat('Heading-', 
		    $current-level)"/>
     <xsl:variable name="simple-heading" select="concat('Simple-', 
		    $current-heading)"/>
     <!-- Catch Heading-N, Heading-NMESSAGE, Simple-Heading-N -->
     <xsl:for-each-group select="$current-group" 
		    group-starting-with="*[starts-with(local-name(.), 
		    $current-heading) or (local-name(.) eq $simple-heading)]">
          <xsl:choose>
             <xsl:when test="(local-name(.) eq $current-heading) or 
			(local-name(.) eq $simple-heading) or (local-name(.) 
			eq 'Heading-2MESSAGE' and $current-level = 2)">
                 <xsl:variable name="the-class" select="if (local-name(.) eq 
			  $simple-heading) then 'message-part' 
			  else if (local-name(.) eq 'Heading-2MESSAGE') 
			  then 'message' 
			  else if (local-name(.) eq $current-heading) 
			  then 'section' else ''" />
                  <xsl:element name="div">
                    <xsl:attribute name="class" select="$the-class"/>
		    <xsl:attribute name="data-fm-style" 
			    select="local-name(.)" />
                    <!-- Recursively capture sections -->
                    <xsl:call-template name="capture-sections">
	  	      <xsl:with-param name="current-level" 
				    select="$current-level + 1"/>
		      <xsl:with-param name="current-group" 
				    select="current-group()"/>
                    </xsl:call-template>
                  </xsl:element>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:copy-of select="current-group()"/>
             </xsl:otherwise>
         </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>


  <xsl:template mode="capture-lists" match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:apply-templates mode="capture-lists-content" select="."/>
    </xsl:copy>
  </xsl:template>

          <xsl:template mode="capture-lists-content" match="*">
            <xsl:apply-templates mode="capture-lists"/>
          </xsl:template>

          <xsl:template mode="capture-lists-content" match="div | CELL">
            <xsl:for-each-group select="*" group-adjacent="my:is-part-of-list(.) and not(self::div or self::CELL)">
              <xsl:apply-templates mode="outer-list" select="."/>
            </xsl:for-each-group>
          </xsl:template>

                  <xsl:template mode="outer-list" match="Number">
                    <ol>
                      <xsl:for-each-group select="current-group()" group-starting-with="Number">
                        <li>
                          <xsl:variable name="nested-bullets-captured" as="element()*">
                            <xsl:call-template name="capture-nested-bullets"/>
                          </xsl:variable>
                          <!-- ASSUMPTION: If there's a nested NumberA list, then it comprises the rest of this list item. -->
                          <xsl:variable name="first-sub-item" select="$nested-bullets-captured[self::NumberA][1]"/>
                          <xsl:for-each-group select="$nested-bullets-captured" group-starting-with="NumberA[. is $first-sub-item]">
                            <xsl:apply-templates mode="inner-numbered-list" select="."/>
                          </xsl:for-each-group>
                        </li>
                      </xsl:for-each-group>
                    </ol>
                  </xsl:template>

                          <xsl:template mode="inner-numbered-list" match="NumberA">
                            <ol>
                              <xsl:for-each-group select="current-group()" group-starting-with="NumberA">
                                <li>
                                  <xsl:apply-templates mode="capture-lists" select="current-group()"/>
                                </li>
                              </xsl:for-each-group>
                            </ol>
                          </xsl:template>

                  <xsl:template mode="outer-list" match="Body-bullet">
                    <ul>
                      <xsl:for-each-group select="current-group()" group-starting-with="Body-bullet">
                        <li>
                          <xsl:call-template name="capture-nested-bullets"/>
                        </li>
                      </xsl:for-each-group>
                    </ul>
                  </xsl:template>

                          <xsl:template name="capture-nested-bullets">
                            <!-- ASSUMPTION: each second-level bulleted list item consists of just one element (Body-bullet-2);
                                 they don't have subsequent paragraphs. -->
                            <xsl:for-each-group select="current-group()" group-adjacent="exists(self::Body-bullet-2)">
                              <xsl:apply-templates mode="inner-list" select="."/>
                            </xsl:for-each-group>
                          </xsl:template>

                                  <xsl:template mode="inner-list" match="Body-bullet-2">
                                    <ul>
                                      <xsl:for-each select="current-group()">
                                        <li>
                                          <xsl:apply-templates mode="capture-lists" select="."/>
                                        </li>
                                      </xsl:for-each>
                                    </ul>
                                  </xsl:template>

                  <xsl:template mode="outer-list" match="Note[my:starts-list(.)]">
                    <NoteWithList>
                      <xsl:call-template name="capture-nested-bullets"/>
                    </NoteWithList>
                  </xsl:template>

                  <!-- If not part of a list, just copy the group through -->
                  <xsl:template mode="outer-list
                                      inner-list
                                      inner-numbered-list" match="*">
                    <xsl:apply-templates mode="capture-lists" select="current-group()"/>
                  </xsl:template>


                  <xsl:function name="my:is-part-of-list">
                    <xsl:param name="e"/>
                    <xsl:sequence select="my:starts-list($e) or my:is-before-end-of-list($e)"/>
                  </xsl:function>

                          <xsl:function name="my:starts-list">
                            <xsl:param name="e"/>
                                                                                           <!-- For when a note contains a list -->
                            <xsl:sequence select="$e/(self::Number or self::Body-bullet or self::Note[following-sibling::*[1]/self::Body-bullet-2])"/>
                          </xsl:function>

                          <xsl:function name="my:ends-list">
                            <xsl:param name="e"/>
                            <xsl:sequence select="$e/(self::EndList-root or self::Body[not(IMAGE)])"/>
                          </xsl:function>

                          <xsl:function name="my:is-before-end-of-list">
                            <xsl:param name="e"/>
                            <xsl:variable name="most-recent-start-or-end-element"
                                          select="$e/preceding-sibling::*[my:starts-list(.) or my:ends-list(.)][1]"/>
                            <!-- We assume that an element is included in the list unless it is a known end-of-list indicator
                                 or one has appeared more recently than the most recent list start. -->
                            <xsl:sequence select="not(my:ends-list($e)) and $most-recent-start-or-end-element[my:starts-list(.)]"/>
                          </xsl:function>

  <xsl:template mode="merge-code-examples" match="node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:apply-templates mode="merge-code-examples-content" select="."/>
    </xsl:copy>
    <xsl:apply-templates mode="merge-code-examples-after" select="."/>
  </xsl:template>

  <xsl:template mode="merge-code-examples" match="@*">
    <xsl:copy/>
  </xsl:template>

          <xsl:template mode="merge-code-examples-content" match="*">
            <xsl:apply-templates mode="merge-code-examples"/>
          </xsl:template>

          <xsl:template mode="merge-code-examples-content" match="li | div | CELL">
            <!-- Merge adjacent Code elements -->
            <xsl:for-each-group select="*" group-adjacent="exists(self::Code)">
              <xsl:apply-templates mode="code-or-not" select="."/>
            </xsl:for-each-group>
          </xsl:template>

                  <xsl:template mode="code-or-not" match="Code">
                    <Code>
                      <!-- Process the content of the adjacent Code elements -->
                      <xsl:apply-templates mode="merge-code-examples" select="current-group()/node()"/>
                    </Code>
                  </xsl:template>

                  <xsl:template mode="code-or-not" match="*">
                    <xsl:apply-templates mode="merge-code-examples" select="current-group()"/>
                  </xsl:template>


          <!-- By default, don't add anything after -->
          <xsl:template mode="merge-code-examples-after" match="node()"/>

          <!-- Add a marker signifying we want to preserve the whitespace at the beginning of this
               Code element (as it's a subsequent adjacent one, which will be merged into the previous) -->
          <xsl:template mode="merge-code-examples-after" match="Code[preceding-sibling::*[1][self::Code]]
                                                               /A[1]">
            <PRESERVE_FOLLOWING_WHITESPACE/>
          </xsl:template>

</xsl:stylesheet>
