xquery version "1.0-ml";

module namespace jwt = "http://developer.marklogic.com/lib/jwt";

import module namespace json="http://marklogic.com/xdmp/json"
  at "/MarkLogic/json/json.xqy";

declare variable $JWT_KEY := "0bd6540c32cd4fb38d5d4e3c866248f1";
declare variable $EPOCH := xs:dateTime(xs:date('1970-01-01Z'));

declare function jwt:jws-custom-encode(
  $result as xs:string
) as xs:string {
  let $result := fn:replace($result, "=", "")
  let $result := fn:replace($result, "\+", "-")
  let $result := fn:replace($result, "/", "_")
  return $result
};

declare function jwt:jws-base64-decode(
  $input as xs:string
) as xs:string {
  let $result := $input
  let $result := fn:replace($result, "\+", "-")
  let $result := fn:replace($result, "/", "_")
  let $mod := fn:string-length($result) mod 4
  let $result :=
    if ($mod = 0) then $result
    else if ($mod = 2) then $result || '=='
    else if ($mod = 3) then $result || '='
    else $result (: or error :)
  let $result := xdmp:base64-decode($result)
  return $result
};

declare function jwt:build-signature(
  $algo as xs:string,
  $mixed as xs:string,
  $key as xs:string
) as xs:string {
  let $result := 
    if ($algo = "HS256") then
      xdmp:hmac-sha256($key, $mixed, "base64")
    else if ($algo = "HS512") then
      xdmp:hmac-sha512($key, $mixed, "base64")
    else
      fn:error((), fn:concat("algorithm (", $algo, ")not supported"))
  return jwt:jws-custom-encode($result)
};

declare function jwt:get-content(
  $token as xs:string,
  $key as xs:string
) as map:map {
  let $parts := fn:tokenize($token, "\.")
  let $header := $parts[1]
  let $content := $parts[2]
  let $signature := $parts[3]
  let $mixed := fn:string-join(($header, $content), ".")
  (: decoded header:)
  let $dhead := xdmp:from-json(jwt:jws-base64-decode($header))
  let $algo := map:get($dhead, "alg")
  let $algo := map:get($dhead, "alg")
  let $computed := jwt:build-signature($algo, $mixed, $key)
  where $computed = $signature
  return xdmp:from-json(jwt:jws-base64-decode($content))
};

declare function jwt:validate-claims(
  $payload as map:map
) as xs:boolean {
  (:TODO: should include validation of 'aud' and 'iat' :)
  let $cur-date := fn:adjust-dateTime-to-timezone(fn:current-dateTime(), xs:dayTimeDuration("PT0H"))
  let $current := jwt:dateTime-to-seconds($cur-date)
  return 
    if (fn:empty(map:get($payload, "exp"))) then fn:false()
    else if (map:get($payload, "exp") lt $current) then fn:false()
    else if (fn:not(fn:empty(map:get($payload, "nbf"))) and map:get($payload, "nbf") gt $current) then fn:false()
    else true()
};

declare function jwt:seconds-to-dateTime(
  $timestamp as xs:long
) as xs:dateTime {
  $EPOCH + xs:dayTimeDuration(fn:concat("PT"||$timestamp||"S"))
};

declare function jwt:dateTime-to-seconds(
  $dateTime as xs:dateTime
) as xs:long {
  let $duration := $dateTime - $EPOCH
  return xs:long($duration div xs:dayTimeDuration('PT1S'))
};
