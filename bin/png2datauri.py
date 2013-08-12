#!/usr/bin/env python
# coding: utf-8
# yc@2013/06/18

import requests, base64, sys

if len(sys.argv) != 2:
    print 'Usage: python %s <image>' % sys.argv[0]
    sys.exit(1)

# smush it
r = requests.post('http://www.smushit.com/ysmush.it/ws.php', \
        files={'files[]': open(sys.argv[1], 'rb')})
out = requests.get(r.json()['dest']).content

# encode it
print 'data:image/png;base64,' + base64.b64encode(out)
