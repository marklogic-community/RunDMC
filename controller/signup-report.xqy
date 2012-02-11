xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";
    
let $_ := xdmp:set-response-content-type('text/html')
let $total := xdmp:estimate(/person)

return
<html>

Total signups to date: {$total} 

<table>
<thead>
<tr>
<td><b>Name</b></td>
<td><b>Email</b></td>
<td><b>Signup date</b></td>
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
</tr>
}
</table>
</html>
