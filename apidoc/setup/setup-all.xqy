import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

declare variable $versions := u:get-doc("/config/server-versions.xml")/*/*:version/@number/string(.);

<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Set up content</title>
		<script type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
  </head>
  <body>
    <h1>Setup all content</h1>
    <table cellspacing="0" cellpadding="10">
      <tr>
        <th>&#160;</th>
        <th>Step 1: Guides</th>
        <th>Step 2: Functions, TOC, etc.</th>
      </tr>
      {
      for $v in $versions return
        <tr>
          <th>{$v}</th>
          <td><pre id="v{$v}part1">Loading...</pre></td>
          <td><pre id="v{$v}part2">Waiting...</pre></td>
        </tr>
      }
    </table>
    <p>See ErrorLog for more granular progress.</p>
    {
    for $v in $versions
    let $v-escaped := replace($v, "\.", "\\\\.") (: "v.1" -> "v\\.1" :)
    return
      <script>
        $(function(){{
          console.log($("body"));
          console.log($("#v{$v-escaped}part1"));
          $("#v{$v-escaped}part1").load("/apidoc/setup/setup-guides.xqy?version={$v}",
              function(response, status, xhr) {{
                if (status == "error") {{
                  $("#v{$v-escaped}part1").parent().html(response);
                  $("#v{$v-escaped}part2").html("Aborted.");
                }} else {{
                  $("#v{$v-escaped}part2").html("Loading...");
                  $("#v{$v-escaped}part2").load("/apidoc/setup/setup.xqy?version={$v}",
                      function(response, status, xhr) {{
                        if (status == "error") {{
                          $("#v{$v-escaped}part2").parent().html(response);
                        }}
                      }});
                  }}
              }})
        }});
      </script>
    }
  </body>
</html>
