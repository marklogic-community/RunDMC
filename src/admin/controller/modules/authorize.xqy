xquery version "1.0-ml";

module namespace authorize = "http://marklogic.com/rundmc/authorize";

(: Determine if the currently logged in user has the admin role, either the MarkLogic
 role or the DMC role. :)
declare function authorize:is-admin() as xs:boolean*
{
  let $user-roles := xdmp:get-current-roles()
  let $admin-roles := (xdmp:role("dmc-admin"), xdmp:role("admin"))
  let $log := xdmp:log($user-roles)
  return
    if($user-roles = $admin-roles) then
      true()
    else
      false()
};
