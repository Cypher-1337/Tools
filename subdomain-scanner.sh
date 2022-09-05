#!/bin/bash


#_____________________________Starting_________________________________________
url=$1

if [[ $# -ne 1 ]];then
    echo "Please Enter URL to scan  EG: https://www.sony.com"
    exit 1
fi

# making subdomains directory
if [ ! -d "subdomains" ]; then
    mkdir subdomains
fi

# extract domain name
domain=$( echo "$url" | sed 's~http[s]*://~~g' )     
echo $domain

# check if the domain folder exist
if [ -d "subdomains/$domain" ]; then
    echo "folder $domain exists."
    #exit 1
else
    mkdir subdomains/$domain
fi
  


#_____________________ IDENTIFY WEB APPLICATION TECHNOLOGIES. ________________________

whatweb -v -a 3 $url >> subdomains/$domain/whatweb_results.txt



#________________________ WAYBACKURLS ___________________________________ 

echo -e "\n_______________________   START WAYBACK   _______________________\n"


if [ ! -d "subdomains/$domain/gau" ]; then
    mkdir subdomains/$domain/gau
fi

waybackurls $domain | grep -v '\.\(jpg\|jpeg\|gif\|css\|tiff\|png\|ttf\|woff\|woff2\|ico\|pdf\|svg\)$' | sort -u >> subdomains/$domain/gau/gau_results.txt

gau $domain | grep -v '\.\(jpg\|jpeg\|gif\|css\|tiff\|png\|ttf\|woff\|woff2\|ico\|pdf\|svg\)$' | sort -u >> subdomains/$domain/gau/gau_results.txt
cat subdomains/$domain/gau/gau_results.txt | uro | sort -u >> subdomains/$domain/gau/temp_gau_results.txt ; rm subdomains/$domain/gau/gau_results.txt ; mv subdomains/$domain/gau/temp_gau_results.txt subdomains/$domain/gau/gau_results.txt

# check if gau_results.txt is empty or not
filesize=$(ls -lh subdomains/$domain/gau/gau_results.txt | awk '{print  $5}')


if [ $filesize -le 1 ]; then
# gau_results.txt is empty then remove gau folder and echo report to $domain folder

    echo "[-] gau_results.txt is empty can't proceed."
    rm -r subdomains/$domain/gau

    echo "[-] There is no wayback records for $domain. " > subdomains/$domain/error_report.txt


else
# gau_results.txt not empty proceed

    cat subdomains/$domain/gau/gau_results.txt | grep '\.\(php\|asp\|aspx\|py\|bak\|db\|config\|zip\|gz\|txt\|wsdl\|git\|sql\)$' >> subdomains/$domain/gau/extensions_file.txt 
    cat subdomains/$domain/gau/extensions_file.txt | sort -u >> subdomains/$domain/gau/temp_extensions_file.txt ; rm subdomains/$domain/gau/extensions_file.txt ; mv subdomains/$domain/gau/temp_extensions_file.txt subdomains/$domain/gau/extensions_file.txt

    cat subdomains/$domain/gau/gau_results.txt | grep '=' >> subdomains/$domain/gau/param_results.txt
    cat subdomains/$domain/gau/param_results.txt | sort -u >> subdomains/$domain/gau/temp_param_results.txt ; rm subdomains/$domain/gau/param_results.txt ; mv subdomains/$domain/gau/temp_param_results.txt subdomains/$domain/gau/param_results.txt

fi


#________________________         CRAWLING        ___________________________________ 

echo -e "\n_______________________   START CRAWLING   _______________________\n"


if [ ! -d "subdomains/$domain/crawler" ]; then
    mkdir subdomains/$domain/crawler
fi

echo $url | hakrawler -subs >> subdomains/$domain/crawler/hakrawler_results.txt
cat subdomains/$domain/crawler/hakrawler_results.txt | sort -u >> subdomains/$domain/crawler/temp_hakrawler_results.txt ; rm subdomains/$domain/crawler/hakrawler_results.txt ; mv subdomains/$domain/crawler/temp_hakrawler_results.txt subdomains/$domain/crawler/hakrawler_results.txt

gospider -s $url >> subdomains/$domain/crawler/gospider_results.txt
cat subdomains/$domain/crawler/gospider_results.txt | sort -u >> subdomains/$domain/crawler/temp_gospider_results.txt ; rm subdomains/$domain/crawler/gospider_results.txt ; mv subdomains/$domain/crawler/temp_gospider_results.txt subdomains/$domain/crawler/gospider_results.txt

# grap parameters
cat subdomains/$domain/crawler/hakrawler_results.txt | grep '=' >> subdomains/$domain/crawler/crawler_params.txt
cat subdomains/$domain/crawler/gospider_results.txt | grep '=' >> subdomains/$domain/crawler/crawler_params.txt
cat subdomains/$domain/crawler/crawler_params.txt | sort -u >> subdomains/$domain/crawler/temp_crawler_params.txt ; rm subdomains/$domain/crawler/crawler_params.txt ; mv subdomains/$domain/crawler/temp_crawler_params.txt subdomains/$domain/crawler/crawler_params.txt

# grap linkfinder links from gospider
cat subdomains/$domain/crawler/gospider_results.txt | grep 'linkfinder' >> subdomains/$domain/crawler/linkfinder_crawler.txt
cat subdomains/$domain/crawler/linkfinder_crawler.txt | sort -u >> subdomains/$domain/crawler/temp_linkfinder_crawler.txt; rm subdomains/$domain/crawler/linkfinder_crawler.txt ; mv subdomains/$domain/crawler/temp_linkfinder_crawler.txt subdomains/$domain/crawler/linkfinder_crawler.txt



#______________________________ JS FILES ___________________________________ 


echo -e "\n_______________________   COLLECTING JS FILES   _______________________\n"


if [ ! -d "subdomains/$domain/js" ]; then
    mkdir subdomains/$domain/js
fi

# if there is no gau results
if [ -d "subdomains/$domain/gau" ]; then
    cat subdomains/$domain/gau/gau_results.txt | grep '\.\(js\)'  >> subdomains/$domain/js/js_files.txt
fi

cat subdomains/$domain/crawler/hakrawler_results.txt | grep '\.\(js\)'  >> subdomains/$domain/js/js_files.txt

cat subdomains/$domain/js/js_files.txt | sort -u >> subdomains/$domain/js/temp_js_files.txt | rm subdomains/$domain/js/js_files.txt ; mv subdomains/$domain/js/temp_js_files.txt subdomains/$domain/js/js_files.txt

cat subdomains/$domain/js/js_files.txt | httpx -mc 200 >> subdomains/$domain/js/live_js_files.txt


jsSize=$(ls -lh subdomains/$domain/js/js_files.txt | awk '{print  $5}')

if [ $jsSize -le 1 ]; then
# js_files.txt is empty then remove js folder and echo report to $domain folder

    echo "[-] There is no js links."

    rm -r subdomains/$domain/js

    echo "[-] There is no js links." >> subdomains/$domain/error_report.txt
  
else

    # running linkfinder
    for url in $(cat subdomains/$domain/js/live_js_files.txt);do

    echo ""; echo "Running Against:  $url" >> subdomains/$domain/js/temp_linkfinder.txt
    echo "" >> subdomains/$domain/js/temp_linkfinder.txt
    python3 /home/cypher/Desktop/tools/LinkFinder/linkfinder.py  -i $url -o cli >> subdomains/$domain/js/temp_linkfinder.txt


    echo "" >> subdomains/$domain/js/temp_linkfinder.txt
    echo "________________________________________________________________" >> subdomains/$domain/js/temp_linkfinder.txt

    cat subdomains/$domain/js/temp_linkfinder.txt | grep -v text/xml | grep -v text/plain | grep -v text/html | grep -v application/x-www-form-urlencoded | grep -v text/javascript| grep -v mm/dd/yy | grep -v next/prev |grep -v valid/invalid | grep -v text/css | grep -v "http://www.w3.org/2000/svg" | grep -v http://www.w3.org/1999/xlink | grep -v MM/dd/yyyy | grep -v audio/x-flv | grep -v video/x-flv | grep -v application/x-shockwave-flash | grep -v false/undefined | grep -v multipart/form-data | grep -v .jpg | grep -v .png | grep -v jpeg | grep -v "valid/invalid" | grep -v "mm/dd/yy" | grep -v "next/prev" | grep -v "text/javascript" | grep -v "www.w3.org" >> subdomains/$domain/js/linkfinder.txt ; rm subdomains/$domain/js/temp_linkfinder.txt 

    done

fi


#______________________________ PARAMS ___________________________________ 

echo -e "\n_______________________   COLLECTING PARAMS   _______________________\n"


if [ ! -d "subdomains/$domain/params" ]; then
    mkdir subdomains/$domain/params
fi

python3 /home/cypher/Desktop/tools/paramSpider/paramspider.py --domain $domain --e woff,css,js,png,svg,jpg --output subdomains/$domain/params/all_params.txt

# if there is no gau results
if [ -d "subdomains/$domain/gau" ]; then
    cat subdomains/$domain/gau/param_results.txt >> subdomains/$domain/params/all_params.txt
fi

cat subdomains/$domain/crawler/crawler_params.txt | cut -d' ' -f3 | grep http >> subdomains/$domain/params/all_params.txt

cat subdomains/$domain/params/all_params.txt | sort -u >> subdomains/$domain/params/temp_all_params.txt ; rm subdomains/$domain/params/all_params.txt ; mv subdomains/$domain/params/temp_all_params.txt subdomains/$domain/params/all_params.txt


paramSize=$(ls -lh subdomains/$domain/params/all_params.txt | awk '{print  $5}')

if [ $paramSize -le 1 ]; then

    echo "[-] There is no params"
    rm -r subdomains/$domain/params
    echo "[-] There is no params" >> subdomains/$domain/error_report.txt

else
    cat subdomains/$domain/params/all_params.txt | qsreplace | sort -u >> subdomains/$domain/params/filter_params.txt

    if [ ! -d "subdomains/$domain/params/gf" ]; then
        mkdir subdomains/$domain/params/gf
    fi


    echo -e "\n_______________________   Gf    _______________________\n"


    ######### RUNNING GF ON parameters #########
    cat subdomains/$domain/params/filter_params.txt | gf xss | sed 's/=.*/=/' | sed 's/URL: //' | sort -u >> subdomains/$domain/params/gf/xss_test.txt
    cat subdomains/$domain/params/filter_params.txt | gf sqli | sed 's/=.*/=/' | sed 's/URL: //' | sort -u >> subdomains/$domain/params/gf/sqli_test.txt
    cat subdomains/$domain/params/filter_params.txt | gf ssrf | sed 's/=.*/=/' | sed 's/URL: //' | sort -u >> subdomains/$domain/params/gf/ssrf_test.txt
    cat subdomains/$domain/params/filter_params.txt | gf lfi | sed 's/=.*/=/' | sed 's/URL: //' | sort -u >> subdomains/$domain/params/gf/lfi_test.txt
    cat subdomains/$domain/params/filter_params.txt | gf redirect | sed 's/=.*/=/' | sed 's/URL: //' | sort -u >> subdomains/$domain/params/gf/redirect_test.txt
    cat subdomains/$domain/params/filter_params.txt | gf idor | sed 's/=.*/=/' | sed 's/URL: //' | sort -u >> subdomains/$domain/params/gf/idor_test.txt


    if [ ! -d "subdomains/$domain/params/gf/scan" ]; then
        mkdir subdomains/$domain/params/gf/scan
    fi


    echo -e "\n_______________________   kxss    _______________________\n"

    # scanning gf xss results for potential vulnerability
    cat subdomains/$domain/params/filter_params.txt | kxss | grep '<' |sed 's/=.*/=/' | sed 's/URL: //'  >> subdomains/$domain/params/gf/scan/xss.txt

fi
