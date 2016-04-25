#!/usr/bin/env python
#-*- coding:utf-8 -*-
__author__ = 'https://github.com/password123456/'

import os
import urllib, urllib2
from xml.dom import minidom

class SPLUNK_CLASS:
    _base_url = 'https://your.splunk.com:8089'
    _username = ''
    _session_key = ''

    def __init__(self, username, password):
        # Login and get the session key
        request = urllib2.Request(self._base_url + '/servicesNS/%s/search/auth/login' % (username),
        data = urllib.urlencode({'username': username, 'password': password}))
        server_content = urllib2.urlopen(request)

        session_key = minidom.parseString(server_content.read()).\
            getElementsByTagName('sessionKey')[0].childNodes[0].nodeValue
        print "Session Key: %s" % session_key

        self._session_key = session_key
        self._username = username

    def search(self, query):
        # Perform a search
        request = urllib2.Request(self._base_url + '/servicesNS/%s/search/search/jobs/export' % (self._username),
            data = urllib.urlencode({'count': 100, 'search': query, 'output_mode': 'csv'}),
            headers = { 'Authorization': ('Splunk %s' % self._session_key)})
        try:
            res = urllib2.urlopen(request)
            query_result = res.read()
            if len(query_result) != 0:
                print len(query_result)
                print query_result
                _QUERY_VAL = 'true'
            else:
                print('[-] splunk query : %d / no result' % len(query_result))
                _QUERY_VAL = 'false'

        except urllib2.HTTPError, e:
            _QUERY_VAL = 'false'
            print('[-] splunk query HTTP error: %d' % e.code)


def main():
    query = '''Your Query 
    ex) index=security | table datetime ~~ blah..blah..'''

#    query = 'search index=asset_dnsa'

    splunk.search(query)

if __name__ == '__main__':
    splunk = SPLUNK_CLASS('$username','$password')
    main()
