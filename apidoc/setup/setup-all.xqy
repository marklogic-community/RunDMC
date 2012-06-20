import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

declare variable $versions := u:get-doc("/config/server-versions.xml")/*/*:version/@number/string(.);

<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Set up all content</title>
		<script type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
    <style type="text/css">
      td,th {{border-bottom: thin solid}}
      .versionCol {{border-left: thin solid;
                    border-right: thin solid;}}
      .deletecol {{border-right: thin solid}}
      .lastRow td {{border: none; }}
    </style>
  </head>
  <body>
    <h1>Set up all content</h1>
    <p>WARNING: This page should generally only be used on the staging server. Running this on the production machine (especially when running a clean build) would cause
    a service interruption for users.</p>
    <p>This page has many buttons. The simplest usage is to click the "Load and set up all docs!" button, which will run the load and setup processes
       for all the server versions in parallel. At the end, it will run the category tagger (which is what enables faceted search) and the search-page generator (for the standalone API docs).</p>
    <p>To run a clean build of everything, first click "Delete all docs!", wait until it's finished, and then click the "Load and set up all docs!" button.</p>
    <p>Alternatively, you can run a delete or setup process for just one server version, e.g. "Load and set up all 5.0 docs".</p>
    <p>Finally, the individual parts (steps 1–3 and their lettered sub-steps) can be invoked individually. These are provided
       for debugging purposes and also to give a visual hint as to the current progress of the setup tasks. For even more granular
       tracking, watch the ErrorLog file while a setup task is running.</p>
    <p>Source directory for loading raw docs:                                    <input id="src-dir-prefix"  size="50" type="text" value="/space/elenz/api-rawdocs/"/> (must end with slash)</p>
    <p>Base directory for static docs (see also /apidoc/config/static-docs.xml): <input id="static-base-dir" size="50" type="text" value="/space/elenz/"/>             (must end with slash)</p>
    <table cellspacing="0" cellpadding="10">
      <colgroup span="1" style="border-right: thin solid"></colgroup>
      <colgroup span="1" style="border-right: thin solid; background-color:#FFDDDD;"></colgroup>
      <colgroup span="1"                           style="background-color:#DDFFDD;"></colgroup>
      <tr style="border-width:1px; border-color:black">
        <th>&#160;</th>
        <th class="deleteCol">
          <input type="button" id="deleteAll" value="Delete all docs!"/>
        </th>
        <th>
          <input type="button" id="runAll" value="Load and set up all docs!"/>
        </th>
        <th>Step 1: Load raw docs<br/><span style="font-size:.8em">(into the "{$raw:db-name}" database)</span></th>
        <th>Step 2: Set up guides<br/><span style="font-size:.8em">(in the "{xdmp:database-name(xdmp:database())}" database (mostly))</span></th>
        <th>Step 3: Set up functions, TOC, etc.<br/><span style="font-size:.8em">(in the "{xdmp:database-name(xdmp:database())}" database)</span></th>
      </tr>
      {
      let $last := count($versions)
      for $v at $position in $versions
      let $src-dir := concat(
                        if ($position eq $last) then "latest"
                                                else concat("b",replace($v,"\.","_")),
                        "_XML")
      return
      (
        <tr>
          <th rowspan="2" class="versionCol">{$v}</th>
          <th class="deleteCol">
            <div>
              <input type="button" class="deleteButton" value="Delete /{$v} docs (raw DB)" title="/apidoc/setup/delete-raw-docs.xqy?version={$v}"/>
            </div>
            <div>
              <input type="button" class="deleteButton" value="Delete /apidoc/{$v} (live DB)" title="/apidoc/setup/delete-docs.xqy?version={$v}"/>
            </div>
          </th>
          <th>{()(:Don't change this to <td> without changing the JS first:)}
            <div>
              <input type="button" class="runVersion" value="Load and set up all {$v} docs ->"/>
            </div>
          </th>
          <td>
            <ol type="a">
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/load-raw-docs.xqy?version={$v}&amp;srcdir={$src-dir}"
                                                        value="Load {$v} raw docs from {$src-dir}"/>
              </li>
            </ol>
          </td>
          <td valign="top">
            <input type="button" class="runSection" value="Set up {$v} guides"/>
            <ol type="a">
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/consolidate-guides.xqy?version={$v}" value="Consolidate {$v} guides"/>
              </li>
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/convert-guides.xqy?version={$v}"     value="Convert {$v} guides"/>
              </li>
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/copy-guide-images.xqy?version={$v}"  value="Copy {$v} guide images"/>
              </li>
            </ol>
          </td>
          <td>
            <input type="button" class="runSection" value="Set up {$v} functions, TOC, etc."/>
            <ol type="a">
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/pull-function-docs.xqy?version={$v}" value="Pull {$v} function docs"/>
              </li>
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/create-toc.xqy?version={$v}"         value="Create {$v} XML TOC"/>
              </li>
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/render-toc.xqy?version={$v}"         value="Render {$v} HTML TOC"/>
              </li>
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/delete-old-toc.xqy?version={$v}"     value="Delete old {$v} TOC"/>
              </li>
              <li>
                <input class="atomicStep" type="button" title="/apidoc/setup/make-list-pages.xqy?version={$v}"    value="Make {$v} list pages"/>
              </li>
            </ol>
          </td>
        </tr>,
        <tr>
          <td class="deleteCol" style="text-align:center">
            <input type="button" class="deleteButton" value="Delete /pubs/{$v} sub-dirs" title="/apidoc/setup/delete-static-docs.xqy?version={$v}"/>
            <div style="font-size:.8em">(PDF &amp; HTML)</div>
          </td>
          <td style="text-align:center">
            <p>Source dir: <input class="static-sub-dir" size="30" type="text" value="MarkLogic_{if ($v eq '5.0') then '5'
                                                                                            else if ($v eq '5.1') then '5.1ea' else $v}_pubs"/> (no slashes)</p>
            <input class="loadStatic atomicStep" type="button" title="/apidoc/setup/load-static-docs.xqy?version={$v}&amp;staticdir="
                                                               value="Load /pubs/{$v} docs"/>
            <div style="font-size:.8em">(PDF &amp; HTML)</div>
          </td>
          <td>&#160;</td>
          <td>&#160;</td>
          <td>&#160;</td>
        </tr>
      )}
      <tr class="lastRow">
        <td>&#160;</td>
        <td class="deleteCol">&#160;</td>
        <td>
          <input class="finalSteps" type="button" title="/setup/collection-tagger.xqy" value="Run global category tagger"/><br/>
          <input class="finalSteps" type="button" title="/apidoc/setup/make-standalone-search-page.xqy" value="Make standalone search page"/>
        </td>
        <td colspan="4">&#160;</td>
      </tr>
    </table>
    <script>
      <!--
      $(function(){

        // This is updated when you run "setup everything"
        var runFinalSteps = false;

        var invokeStep = function(button, masterButton) {

          var getNextStep = function() {
            var nextSiblingSteps = button.parent()     .nextAll().find(".atomicStep");
            var nextCousinSteps  = button.parents("td").nextAll().find(".atomicStep");

            var nextSteps = masterButton.is(".runVersion") ? nextSiblingSteps.add(nextCousinSteps)
                         : (masterButton.is(".runSection") ? nextSiblingSteps
                                                            : $([]));
            return nextSteps.first();
          };

          var nextStep = masterButton==undefined ? $([]) : getNextStep();

          run(button);

          var url = button.attr("title").replace("srcdir=",
                                                 "srcdir=" + $("#src-dir-prefix").attr("value"))
                                        .replace("staticdir=",
                                                 "staticdir=" +                        $("#static-base-dir").attr("value")
                                                              + button.parents("td").find(".static-sub-dir").attr("value"));
          button.load(url,
            function(response, status, xhr) {
              if (status == "error") {
                button.parent().html(response);
                finish(masterButton, "Aborted");
              } else {
                finish(button, "Finished");
                if (nextStep.length)
                  invokeStep(nextStep, masterButton)
                else {
                  finish(masterButton, "Finished");
                  // If we've just finished running "everything", then run the collection tagger now
                  if (runFinalSteps && $('input[disabled="disabled"]').length==0) {
                    $(".finalSteps").click();
                    runFinalSteps = false;
                  }
                }
              }
            });
        };

        var run = function(button) {
          button.val("RUNNING: " + button.val());
          button.css("color", "red");
          button.attr("disabled","disabled");
        };

        var finish = function(button, msg) {
          button.val(msg + ": " + button.val());
          button.css("color", "inherit");
          button.removeAttr("disabled");
        };

        // Run an individual step
        $(".atomicStep, .deleteButton, .finalSteps").click(function(){
          invokeStep($(this), $([]));
        });

        // Run everything for the given version or section
        $(".runVersion, .runSection").click(function(){
          var firstStep = $(this).closest("tr,td").find(".atomicStep").first();
          run($(this));
          invokeStep(firstStep, $(this));
        });

        // Run every version and every static-doc load (can all be done in parallel)
        $("#runAll").click(function(){
          $(".runVersion").click();
          $(".loadStatic").click();
          runFinalSteps = true;
        });

        // Delete everything that can be deleted
        $("#deleteAll").click(function(){
          $(".deleteButton").click();
        });

      });
    -->
    </script>
  </body>
</html>
