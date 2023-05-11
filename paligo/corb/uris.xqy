xquery version "1.0-ml";

let $uris := cts:uris("", (), cts:directory-query('/paligo/', 'infinity'))
return (fn:count($uris), $uris)