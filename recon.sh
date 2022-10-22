#!/bin/bash


###### COLORS ########
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m' 
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
BCyan='\033[1;36m'
UGreen='\033[4;32m' 
######################

function recon(){

    if [ -d "recon" ]; then
        echo ""
    else
        mkdir recon
    fi

    # if the script executed before when you run it again it will try to find subdomains and compare
    # them with the older one to grap new subdomains if any

    if [ -f "recon/all-subdomains.txt" ]; then

        printf "${BCyan}[+] all-subdomains.txt already existed. grapping new subdomains...\n\n${NC}"

        printf "\n${ORANGE}[+] Gathering subdomains for $1 with Subfinder...${NC}" 
        
            subfinder -d $1 | sort -u >> recon/all2.txt
/httpx/tree/dev/httpx/tree/dev
        printf "\n${ORANGE}[+] Gathering subdomains for $1 with Sublist3r...${NC}" 
        
            sublist3r -d $1 -o recon/subs.txt ; cat recon/subs.txt >> recon/all2.txt ; rm recon/subs.txt

        printf "\n${ORANGE}[+] Gathering subdomains for $1 with Assetfinder...${NC}"
        
            assetfinder -subs-only $1 | sort -u >> recon/all2.txt

        printf "${ORANGE}[+] Gathering subdomains for $1 with github-subdomains..."
            github-subdomains -d $1 -t /home/cypher/tokens/github.txt -o recon/github_domains2.txt
            cat recon/github_domains2.txt >> recon/all2.txt ; rm recon/github_domains2.txt

        printf "\n${ORANGE}[+] Gathering subdomains for $1 with findomain-linux...${NC}\n"
        
            /home/cypher/tools/findomain-linux -t $1 | grep -v 'Searching in the' | grep -v 'Job finished in' | grep -v 'Good luck Hax0r' | grep -v 'Target ==>' >> recon/all2.txt

        printf "\n${ORANGE}[+]Gathering subdomains with amass passive...${NC}\n"
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


#-------------------------------------------------------------------------------------------------------

    else

        # this code will be executed if its first time you run the script 

        printf "\n${ORANGE}[+] Gathering subdomains for $1 with Subfinder...${NC}\n" 
            subfinder -d $1 | sort -u >> recon/all.txt

        printf "\n${ORANGE}[+] Gathering subdomains for $1 with Sublist3r...${NC}\n" 
            sublist3r -d $1 -o recon/subs.txt ; cat recon/subs.txt >> recon/all.txt ; rm recon/subs.txt

        printf "\n${ORANGE}[+] Gathering subdomains for $1 with Assetfinder...${NC}\n"
            assetfinder -subs-only $1 >> recon/all.txt

        printf "\n${ORANGE}[+]Gathering subdomains for $1 with github-subdomains...${NC}\n"
            github-subdomains -d $1 -t /home/cypher/tokens/github.txt -o recon/github_domains.txt
            cat recon/github_domains.txt >> recon/all.txt ; rm recon/github_domains.txt

        printf "\n${ORANGE}[+] Gathering subdomains for $1 with findomain-linux...${NC}\n"
            /home/cypher/tools/findomain-linux -t $1 | grep -v 'Searching in the' | grep -v 'Job finished in' | grep -v 'Good luck Hax0r' | grep -v 'Target ==>' >> recon/all.txt

        printf "\n${ORANGE}[+]Gathering subdomains with amass passive...${NC}\n"
            amass enum -passive -d $1 >> recon/all.txt

            cat recon/all.txt | sort -u >> recon/all-subdomains.txt; rm recon/all.txt


        ############        Probing Subdomains        ############

        printf "\n${BLUE}[+] Gathering alive domains...${NC}\n"
            cat recon/all-subdomains.txt | httpx | tee recon/alive.txt

            cat recon/alive.txt | sed 's~http[s]*://~~g' | sort -u | tee recon/alive_d.txt

         printf "\n${GREEN}[+] getting js files with subjs....${NC}\n"
            mkdir recon/js-files
            cat recon/alive.txt | subjs | sort -u |tee recon/js-files/jsfiles.txt

        printf "\n${GREEN}[+] Getting subdomains ips...${NC}\n"
            cat recon/alive_d.txt | dnsx -silent -a -resp-only | tee recon/ip.txt
            cat recon/ip.txt | sort -u | tee recon/ips.txt ; rm recon/ip.txt

        printf "\n${GREEN}[+] Scan with nrich...${NC}\n"

            mkdir recon/scans
            nrich recon/ips.txt >> recon/scans/nrich_scan.txt

        printf "\n${BLUE}[+] Getting 403 pages for dirsearch.....${NC}\n"
            mkdir recon/403
            cat recon/alive_d.txt | httpx -mc 403 >> recon/403/403.txt


        printf "\n${BLUE}[+] Getting 200 pages......${NC}\n"
            cat recon/alive_d.txt | httpx -mc 200 >> recon/200.txt 

        printf "\n${BLUE}[+] Getting pages sizes and titles.....${NC}\n"
            mkdir recon/httpx
            cat recon/alive_d.txt | httpx --status-code -cl -title -o recon/httpx/httpx_results.txt

            rm recon/alive_d.txt
    fi

}




function wayback(){

# Start Collecting Wayback

    if [ -f "wayback/wayback.txt" ]; then

        printf "\n${GREEN}Running New Wayback${NC}\n\n"

        gauplus -subs $1 | tee wayback/wayback2_gauplus.txt
        gau --subs $1 | tee wayback/wayback2_gau.txt
        waybackurls $1 | tee wayback/wayback2_wayback.txt


        # collecting results to one file
        cat wayback/wayback2_gauplus.txt >> wayback/wayback2.txt ; rm wayback/wayback2_gauplus.txt
        cat wayback/wayback2_gau.txt >> wayback/wayback2.txt ; rm wayback/wayback2_gau.txt
        cat wayback/wayback2_wayback.txt >> wayback/wayback2.txt ; rm wayback/wayback2_wayback.txt


        # filter outputs
        cat wayback/wayback2.txt | sort -u | tee wayback/temp_wayback2.txt; rm wayback/wayback2.txt

        cat wayback/temp_wayback2.txt | grep -a -v '\.\(jpg\|jpeg\|gif\|css\|tiff\|png\|ttf\|woff\|woff2\|ico\|pdf\|svg\)$' | sort -u | tee wayback/wayback_2.txt ; rm wayback/temp_wayback2.txt

        # get new wayback
        if [ -f "wayback/new_wayback.txt" ]; then
            rm wayback/new_wayback.txt
        fi
        
        awk 'FNR==NR {a[$0]++; next} !($0 in a)' wayback/wayback.txt wayback/wayback_2.txt | sort -u >> wayback/new_wayback.txt

        printf "\n\n______________________________________________________\n"
        cat wayback/new_wayback.txt
        printf "\n______________________________________________________\n\n"

        cat wayback/new_wayback.txt >> wayback/wayback.txt
        rm wayback/wayback_2.txt

        if [ ! -d "wayback/new_gf" ]; then
            mkdir wayback/new_gf
        fi


        # gf tool
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



    else



        printf "\n${BLUE}[+] Runing waybackmachines......${NC}\n\n"

        if [ ! -d "wayback" ]; then
            mkdir wayback
        fi

        gauplus -subs $1 | tee wayback/$1_gauplus.txt
        gau --subs $1 | tee wayback/$1_gau.txt
        waybackurls $1 | tee wayback/$1_wayback.txt

        # collecting results to one file
        cat wayback/$1_gauplus.txt >> wayback/$1.txt ; rm wayback/$1_gauplus.txt
        cat wayback/$1_gau.txt >> wayback/$1.txt ; rm wayback/$1_gau.txt
        cat wayback/$1_wayback.txt >> wayback/$1.txt ; rm wayback/$1_wayback.txt

        # filter outputs
        cat wayback/$1.txt | sort -u | tee wayback/temp_wayback.txt; rm wayback/$1.txt
        
        
        cat wayback/temp_wayback.txt | grep -a -v '\.\(jpg\|jpeg\|gif\|css\|tiff\|png\|ttf\|woff\|woff2\|ico\|pdf\|svg\)$'  | sort -u | tee wayback/wayback.txt ; rm wayback/temp_wayback.txt

        # gf tool
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

        cat wayback/wayback.txt |  awk -F '?' '{print $2}' | awk -F '=' '{print $1}' | sort -u >> parameters/wayback_params.txt



        echo "********************   DONE    ************************"



    fi
        

   
}

function scan(){
    nuclei -l recon/alive.txt -o recon/scan/nuclei_results.txt
}


function all(){
    echo $1;
    recon "$1";
    wayback "$1";
}


while getopts r:w:a:s: options; do
    case $options in
        r) recon "$OPTARG";;    # execute recon fucntion
        w) wayback "$OPTARG";;    # execute wayback funtion
        a) all "$OPTARG";;     # domain name
        s) scan ;;              # Scan function
        \?) echo -e "Please provide \n-a for all \n-w for wayback \n-r for recon ";;
    esac
done

