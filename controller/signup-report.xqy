xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare option xdmp:output "method=html";
    
if (xdmp:get-request-field("csv")) then

let $_ := xdmp:set-response-content-type('text/csv')

let $csv := 
string-join(

for $i in /person
order  by $i/created/string() descending
return
string-join(
(
 concat('"', $i/name/string(), '"'), 
 concat('"', $i/email/string(), '"'), 
 concat('"', fn:format-dateTime($i/created, "[Y01]/[M01]/[D01] [H01]:[m01]:[s01]:[f01]"), '"'),
 concat('"', $i/country/string(), '"'), 
 concat('"', $i/organization/string(), '"'), 
 concat('"', $i/list/string(), '"'), 
 concat('"', $i/download[last()]/fwded-for[last()]/string(), '"'), 
 ""
),
","
)

,
"
"
)
return $csv

    
else

let $total := fn:count(/person)
let $_ := xdmp:set-response-content-type('text/html')
return

(xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html lang="en">
<head>
  <style type="text/css">
      body {{ font: 14px/129% Arial, Helvetica, Sans-serif;}}
      table {{ border-collapse: collapse; }}
      td, th {{ border: 1px solid #666; padding: 3px;}}
  </style>
  <script type="text/javascript" src="/js/modernizr.js"></script>
  <script type="text/javascript" src="/js/jquery-1.6.4.min.js"></script>
</head>
<body>
<section>
Total signups to date: {$total} 
&#160;&#160;<button id="button" value="Export to CSV">Export to CSV</button>
</section>

<div>&#160;</div>

<table class="datatable">
<thead>
<tr>
<th><b>Name</b></th>
<th><b>Email</b></th>
<th><b>Signup date</b></th>
<th><b>Country</b></th>
<th><b>Organization</b></th>
<th><b>Dev list</b></th>
<th><b>Latest IP</b></th>
</tr>
</thead>
{
for $i in /person
order  by $i/created/string() descending
return
<tr>
<td>{$i/name/string()}</td>
<td>{$i/email/string()}</td>
<td>{fn:format-dateTime($i/created,"[Y01]/[M01]/[D01] [H01]:[m01]:[s01]:[f01]")}</td>
<td>{$i/country/string()}</td>
<td>{$i/organization/string()}</td>
<td>{$i/list/string()}</td>
<td>{$i/download[last()]/fwded-for[last()]/string()}</td>
</tr>
}
</table>
</body>
<script type="text/javascript">
    $(document).ready(function() {{
        $('#button').click(function() {{
            window.location = '/signup-report?csv=1';
        }});
    }});
</script>
</html>
)
