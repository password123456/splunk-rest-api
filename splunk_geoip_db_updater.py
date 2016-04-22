#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = https://github.com/password123456/

# update source : MAXMIND DB

import os
import time
import urllib2
import gzip
import shutil

url = "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
home_path = "/home/script/splunk_geoip_update"
#unzip_path = "/home/script/filedownload/update/"
#geoip_path = "/opt/splunk/etc/apps/MAXMIND/bin/"
unzip_path = "/home/script/splunk_geoip_update/db"
geoip_path = "/home/script/splunk_geoip_update/bin"

def DOWNLOAD_GEO_IP(url):

	file_name = "%s/%s" % ( home_path, url.split('/')[-1] )
        try:
	    u = urllib2.urlopen(url)
	    f = open(file_name, 'wb')
	    meta = u.info()
	    file_size = int(meta.getheaders("Content-Length")[0])

	    print "[+] Downloading: %s / %.2f MB" % ( file_name, (file_size / (1024.0 * 1024.0)) )
  	    file_size_dl = 0
	    block_sz = 8192
	    while True:
	        buffer = u.read(block_sz)
	        if not buffer:
	            break

	        file_size_dl += len(buffer)
	        f.write(buffer)
	        status = r"%10d Bytes  [%3.2f%%]" % (file_size_dl, file_size_dl * 100. / file_size)
	        status = status + chr(8)*(len(status)+1)
	        print status,

	    f.close()
   	    UPDATED(file_name,unzip_path)

        except urllib2.HTTPError, e:
            print("[-] Download Fail HTTP error: %d" % e.code)


def UPDATED(file_name,unzip_path):
    update_file = "%s/GeoLiteCity.dat" % ( unzip_path )
    #update_file = "%s%s_GeoLiteCity.dat" % ( unzip_path, time.strftime('%Y%m%d') )
    print "[+] Decompress: %s" % ( update_file )

    if not os.path.exists(unzip_path):
        os.makedirs(unzip_path)

    zipFile = gzip.open(file_name, 'rb')
    unCompressedFile = open(update_file,"wb")

    decoded = zipFile.read()
    unCompressedFile.write(decoded)
    zipFile.close()
    unCompressedFile.close()

    splunk_update = update_file.split('/')[-1]
    #updated_file = "%s/%s" % ( updated_path, update_file)
    geoip_file = "%s/%s" % ( geoip_path, splunk_update )

    try:
        shutil.copyfile (update_file, geoip_file)
        os.remove(file_name)
        print "[+] Updating: %s => %s " % ( update_file, geoip_file )
        print "[+] Remove: %s" % ( file_name )

    except shutil.Error as e:
        print('Error: %s' % e)
    except IOError as e:
        print('Error: %s' % e.strerror)

def main():
    DOWNLOAD_GEO_IP(url)

if __name__ == '__main__':
    main()
