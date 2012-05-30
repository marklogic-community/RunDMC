xquery version "1.0-ml";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

xdmp:invoke("do-consolidate-guides.xqy", (), <options xmlns="xdmp:eval">
                                              <database>{xdmp:database($raw:db-name)}</database>
                                            </options>)

, "Done consolidating guides."
