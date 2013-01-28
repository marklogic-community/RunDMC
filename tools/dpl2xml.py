#!/usr/bin/python

"""
    Script to convert denied person list tab-delimtted file to xml
"""

import os
import sys
import csv
import datetime

from xml.etree.ElementTree import Element, SubElement, tostring

if (len(sys.argv) != 2):
    print "Usage: " + sys.argv[0] + " [dpl.txt]"
    sys.exit(-1)

with open(sys.argv[1], 'r') as csvfile:

    root = Element('denied-persons')

    for row in csv.DictReader(csvfile, delimiter='\t'):

        person = Element('person')

        for col, value in row.iteritems():
            el = Element(col)
            # Handle dates
            if (col.endswith('Date') and value != ''):
                el.text = datetime.datetime.strptime(value, "%m/%d/%Y").isoformat()
            # Handle names - put first name first
            elif (col == 'Name' and value.find(',') != -1):
                x = value.partition(',')
                el.text = x[2].strip() + ' ' + x[0].strip()
            else:
                el.text = value
            person.append(el)
            
        root.append(person)


print tostring(root)
    
