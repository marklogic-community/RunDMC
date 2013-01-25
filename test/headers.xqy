for $h in xdmp:get-request-header-names()
return concat($h, ":", xdmp:get-request-header($h))
