#!/bin/bash

java -cp marklogic-corb-2.5.4.jar:marklogic-xcc-11.0.2.jar -DOPTIONS-FILE=task.corb $@ com.marklogic.developer.corb.Manager
