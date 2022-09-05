#!/bin/bash

if [[ $# -ne 1 ]];then
    echo "[-] Please Enter the domain name eg: epicgames.com"
    echo "Exiting Now...."
    exit 1
fi




############        Collecting Subdomains       ############

if [ -d "recon" ]; then
    echo ""
else
    mkdir recon
fi

# if the script executed before when you run it again it will try to find subdomains and compare
# them with the older one to grap new subdomains if any

if [ -f "recon/all-subdomains.txt" ]; then
    echo -e "[+] all-subdomains.txt already existed. grapping new subdomains...\n\n"
    
    echo "[+] Gathering subdomains for $1 with Subfinder..." 
    subfinder -d $1 | sort -u >> recon/all2.txt

    echo "[+] Gathering subdomains for $1 with Sublist3r..." 
    sublist3r -d $1 -o recon/subs.txt ; cat recon/subs.txt >> recon/all2.txt ; rm recon/subs.txt

    echo "[+] Gathering subdomains for $1 with Assetfinder..."
    assetfinder -subs-only $1 | sort -u >> recon/all2.txt

    echo "[+] Gathering subdomains for $1 with github-subdomains..."
    github-subdomains -d $1 -t /home/cypher/tokens/github.txt -o recon/github_domains2.txt
    cat recon/github_domains2.txt >> recon/all2.txt ; rm recon/github_domains2.txt

    echo "[+] Gathering subdomains for $1 with findomain-linux..."
    /home/cypher/tools/findomain-linux -t $1 | grep -v 'Searching in the' | grep -v 'Job finished in' | grep -v 'Good luck Hax0r' | grep -v 'Target ==>' >> recon/all2.txt

    echo "[+] Gathering subdomains with amass passive..."
    amass enum -passive -d $1 >> recon/all2.txt

    cat recon/all2.txt | sort -u >> recon/all-subdomains-2.txt; rm recon/all2.txt
    
    
    if [ -f "recon/new.txt" ]; then
        rm recon/new.txt
    fi
    
    awk 'FNR==NR {a[$0]++; next} !($0 in a)' recon/all-subdomains.txt recon/all-subdomains-2.txt | sort -u >> recon/new.txt

    echo "______________________________________________________"
    cat recon/new.txt
    echo "______________________________________________________"


    cat recon/new.txt >> recon/all-subdomains.txt 
    rm recon/all-subdomains-2.txt
   
    cat recon/new.txt | httpx --status-code -cl -title | tee recon/live_new.txt


# Start Collecting Wayback

    if [ -f "wayback/new_wayback.txt" ]; then
        rm wayback/new_wayback.txt
    fi
    

    gauplus -subs $1 -o wayback/wayback2.txt
    gau --subs $1 >> wayback/wayback2.txt
    waybackurls $1 >> wayback/wayback2.txt
    cat wayback/wayback2.txt | sort -u | tee wayback/new_wayback.txt; rm wayback/wayback2.txt
    cat wayback/new_wayback.txt | grep -v '\.\(jpg\|jpeg\|gif\|css\|tiff\|png\|ttf\|woff\|woff2\|ico\|pdf\|svg\)$' | sort -u | tee wayback/wayback_2.txt ; rm wayback/new_wayback.txt

    awk 'FNR==NR {a[$0]++; next} !($0 in a)' wayback/wayback.txt wayback/wayback_2.txt | sort -u >> wayback/new_wayback.txt

    echo "______________________________________________________"
    cat wayback/new_wayback.txt
    echo "______________________________________________________"

    cat wayback/new_wayback.txt >> wayback/wayback.txt
    rm wayback/wayback_2.txt

    if [ ! -d "wayback/new_gf" ]; then
        mkdir wayback/new_gf
    fi


    cat wayback/new_wayback.txt | gf xss | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/new_gf/new_xss.txt
    cat wayback/new_wayback.txt | gf sqli | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/new_gf/new_sqli.txt
    cat wayback/new_wayback.txt | gf ssrf | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/new_gf/new_ssrf.txt
    cat wayback/new_wayback.txt | gf lfi | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/new_gf/new_lfi.txt
    cat wayback/new_wayback.txt | gf redirect | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/new_gf/new_redirect.txt
    cat wayback/new_wayback.txt | gf idor | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/new_gf/new_idor.txt

# Start Getting Parameters

    if [ ! -d "parameters" ]; then
        mkdir parameters 
    fi

    cat wayback/new_wayback.txt |  awk -F '?' '{print $2}' | awk -F '=' '{print $1}' | sort -u >> parameters/wayback_new_params.txt

#-----------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------

else

    # this code will be executed if its first time you run the script 

    echo "[+] Gathering subdomains for $1 with Subfinder..." 
    subfinder -d $1 | sort -u >> recon/all.txt

    echo "[+] Gathering subdomains for $1 with Sublist3r..." 
    sublist3r -d $1 -o recon/subs.txt ; cat recon/subs.txt >> recon/all.txt ; rm recon/subs.txt

    echo "[+] Gathering subdomains for $1 with Assetfinder..."
    assetfinder -subs-only $1 >> recon/all.txt

    echo "[+] Gathering subdomains for $1 with github-subdomains..."
    github-subdomains -d $1 -t /home/cypher/tokens/github.txt -o recon/github_domains.txt
    cat recon/github_domains.txt >> recon/all.txt ; rm recon/github_domains.txt

    echo "[+] Gathering subdomains for $1 with findomain-linux..."
    /home/cypher/tools/findomain-linux -t $1 | grep -v 'Searching in the' | grep -v 'Job finished in' | grep -v 'Good luck Hax0r' | grep -v 'Target ==>' >> recon/all.txt

    echo "[+] Gathering subdomains with amass passive..."
    amass enum -passive -d $1 >> recon/all.txt

    cat recon/all.txt | sort -u >> recon/all-subdomains.txt; rm recon/all.txt


    ############        Probing Subdomains        ############

    echo "[+] Gathering alive domains..."
    cat recon/all-subdomains.txt | httpx | tee recon/alive.txt

    cat recon/alive.txt | sed 's~http[s]*://~~g' | sort -u | tee recon/alive_d.txt

    echo "[+] getting js files with subjs...."
    mkdir recon/js-files
    cat recon/alive.txt | subjs | sort -u |tee recon/js-files/jsfiles.txt

    echo "[+] Getting subdomains ips..."
    cat recon/alive_d.txt | dnsx -silent -a -resp-only | tee recon/ip.txt
    cat recon/ip.txt | sort -u | tee recon/ips.txt ; rm recon/ip.txt

    echo "[+] Getting 403 pages for dirsearch....."
    mkdir recon/403
    cat recon/alive_d.txt | httpx -mc 403 >> recon/403/403.txt


    echo "[+] Getting 200 pages......"
    cat recon/alive_d.txt | httpx -mc 200 >> recon/200.txt 

    echo "[+] Getting pages sizes and titles....."
    mkdir recon/httpx
    cat recon/alive_d.txt | httpx --status-code -cl -title -o recon/httpx/httpx_results.txt

    rm recon/alive_d.txt

   
    #__________________________     WAYBACKMACHINE      ________________________________________________

    echo "[+] Runing waybackmachines......"

    if [ ! -d "wayback" ]; then
        mkdir wayback
    fi

    gauplus -subs $1 -o wayback/$1.txt
    gau --subs $1 >> wayback/$1.txt
    waybackurls $1 >> wayback/$1.txt
    cat wayback/$1.txt | sort -u | tee wayback/temp_wayback.txt; rm wayback/$1.txt
    cat wayback/temp_wayback.txt | grep -v '\.\(jpg\|jpeg\|gif\|css\|tiff\|png\|ttf\|woff\|woff2\|ico\|pdf\|svg\)$'  | sort -u | tee wayback/wayback.txt ; rm wayback/temp_wayback.txt

    mkdir wayback/gf
    cat wayback/wayback.txt | gf xss | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/gf/xss_test.txt
    cat wayback/wayback.txt | gf sqli | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/gf/sqli_test.txt
    cat wayback/wayback.txt | gf ssrf | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/gf/ssrf_test.txt
    cat wayback/wayback.txt | gf lfi | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/gf/lfi_test.txt
    cat wayback/wayback.txt | gf redirect | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/gf/redirect_test.txt
    cat wayback/wayback.txt | gf idor | sed 's/=.*/=/' | sed 's/URL: //' | sort -u |tee wayback/gf/idor_test.txt


# Start Getting Parameters

    if [ ! -d "parameters" ]; then
        mkdir parameters
    fi

    cat wayback/wayback.txt|  awk -F '?' '{print $2}' | awk -F '=' '{print $1}' | sort -u >> parameters/wayback_params.txt



    echo "********************   DONE    ************************"


fi

# Testing git pull request
