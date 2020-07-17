import hashlib
import urllib
import logging
import json

def lambda_handler(event, context):
    return get_hash('https://ip-ranges.amazonaws.com/ip-ranges.json')

def get_hash(url):
    
    logging.debug("Updating from " + url)

    response = urllib.request.urlopen(url)
    ip_json = response.read()

    m = hashlib.md5()
    m.update(ip_json)

    return {'result': m.hexdigest()}