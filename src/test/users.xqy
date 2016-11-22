xquery version "1.0-ml";

(: Test module for lib/users.xqy :)

module namespace t="http://github.com/robwhitby/xray/test";

import module namespace users="users" at "/lib/users.xqy";
import module namespace assert="http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

declare variable $user1-id := "12345678901234567890";
declare variable $user2-id := "23456789012345678901";
declare variable $user3-id := "34567890123456789012";

declare %t:setup function t:setup()
{
  xdmp:document-insert(
    "/private/people/" || $user1-id || ".xml",
    <person>
      <id>12345678901234567890</id>
      <email>test-1@fake-email.com</email>
      <name>Fake User1</name>
      <password>4O.SIJgwgtafmmvXuJryy1</password>
      <created>2016-11-21T15:39:38.925926-05:00</created>
      <organization>MarkLogic</organization>
      <industry>Technology - Software</industry>
      <phone>484-555-1212</phone>
      <country>United States of America</country>
      <state>PA</state>
      <list>off</list>
      <contact-me>off</contact-me>
    </person>
  ),
  xdmp:document-insert(
    "/private/people/" || $user2-id || ".xml",
    <person>
      <id>23456789012345678901</id>
      <email>test-2@fake-email.com</email>
      <name>Fake User2</name>
      <password>4O.SIJgwgtafmmvXuJryy1</password>
      <created>2016-11-21T15:39:38.925926-05:00</created>
      <organization>MarkLogic</organization>
      <industry>Technology - Software</industry>
      <phone>484-555-1212</phone>
      <country>United States of America</country>
      <state>PA</state>
      <list>off</list>
      <contact-me>off</contact-me>
      <preferences/>
    </person>
  ),
  xdmp:document-insert(
    "/private/people/" || $user3-id || ".xml",
    <person>
      <id>34567890123456789012</id>
      <email>test-3@fake-email.com</email>
      <name>Fake User3</name>
      <password>4O.SIJgwgtafmmvXuJryy1</password>
      <created>2016-11-21T15:39:38.925926-05:00</created>
      <organization>MarkLogic</organization>
      <industry>Technology - Software</industry>
      <phone>484-555-1212</phone>
      <country>United States of America</country>
      <state>PA</state>
      <list>off</list>
      <contact-me>off</contact-me>
      <preferences>
        <doc-section>original value</doc-section>
      </preferences>
    </person>
  )
};

declare %t:teardown function t:teardown()
{
  ( $user1-id, $user2-id, $user3-id) !
    xdmp:document-delete("/private/people/" || . || ".xml")
};

declare %t:case function t:invalid-preference()
{
  assert:false(
    users:valid-preference("invalid")
  )
};

declare %t:case function t:set-pref-no-user()
{
  let $actual :=
    try {
      users:set-preference((), "doc-section", "value")
    } catch ($ex) {
      <wtf/>,
      $ex
    }
  return (
    assert:equal($actual/error:name/fn:string(), "NO-USER")
  )
};

(:
 : The user already has this preference and we're changing it.
 : Since we're making actual database updates, we need to do the write and read
 : in separate transactions.
 :)
declare %t:case function t:set-pref-override-pref()
{
  xdmp:eval(
    'import module namespace users="users" at "/lib/users.xqy";
     declare variable $user-id external;
     declare variable $user := users:getUserByID($user-id);
     users:set-preference($user, "doc-section", "new-value")',
    map:new((map:entry("user-id", $user1-id)))
  ),
  let $actual :=
    xdmp:eval(
      'import module namespace users="users" at "/lib/users.xqy";
       declare variable $user-id external;
       users:getUserByID($user-id)',
      map:new((map:entry("user-id", $user1-id)))
    )
  return assert:equal($actual/preferences/doc-section/fn:string(), "new-value")
};

(:
 : The user does not have this preference setting yet, but does have a
 : <preferences/> element.
 : Since we're making actual database updates, we need to do the write and read
 : in separate transactions.
 :)
declare %t:case function t:set-pref-create-pref()
{
  xdmp:eval(
    'import module namespace users="users" at "/lib/users.xqy";
     declare variable $user-id external;
     declare variable $user := users:getUserByID($user-id);
     users:set-preference($user, "doc-section", "new-value")',
    map:new((map:entry("user-id", $user2-id)))
  ),
  let $actual :=
    xdmp:eval(
      'import module namespace users="users" at "/lib/users.xqy";
       declare variable $user-id external;
       users:getUserByID($user-id)',
      map:new((map:entry("user-id", $user2-id)))
    )
  return assert:equal($actual/preferences/doc-section/fn:string(), "new-value")
};

(:
 : The user does not have even have a <preferences/> element.
 : Since we're making actual database updates, we need to do the write and read
 : in separate transactions.
 :)
declare %t:case function t:set-pref-create-first-pref()
{
  xdmp:eval(
    'import module namespace users="users" at "/lib/users.xqy";
     declare variable $user-id external;
     declare variable $user := users:getUserByID($user-id);
     users:set-preference($user, "doc-section", "new-value")',
    map:new((map:entry("user-id", $user3-id)))
  ),
  let $actual :=
    xdmp:eval(
      'import module namespace users="users" at "/lib/users.xqy";
       declare variable $user-id external;
       users:getUserByID($user-id)',
      map:new((map:entry("user-id", $user3-id)))
    )
  return assert:equal($actual/preferences/doc-section/fn:string(), "new-value")
};

declare %t:case function t:get-unset-pref()
{
  assert:empty(
    users:get-user-preference(users:getUserByID($user3-id), "no-such-preference")
  )
};

declare %t:case function t:get-set-pref()
{
  assert:equal(
    users:get-user-preference(
      users:getUserByID($user3-id),
      $users:PREF-DOC-SECTION),
    "original value"
  )
};
