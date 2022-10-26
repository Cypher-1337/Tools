#!/bin/bash

<<<<<<< HEAD
=======
#### TO DO ####

# add chameleon to the script





>>>>>>> 12061c4 (developing Bash Recon project)
###### COLORS ########
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m' 
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
BCyan='\033[1;36m'
UGreen='\033[4;32m' 
######################


if [ ! -d "scanner" ]; then
    mkdir scanner
fi

function fuzz(){


    printf "${ORANGE}[+] Directory Fuzzing against:\t\t $1 \n\n${NC}"

    if [ -f "/usr/lib/python3/dist-packages/dirsearch/results.txt" ]; then
        rm /usr/lib/python3/dist-packages/dirsearch/results.txt
    fi

    dirsearch -u $1 -o results.txt

    tail -n +3 /usr/lib/python3/dist-packages/dirsearch/results.txt > scanner/dirsearch.txt


    dir_count=0
    while read dir; do

        status=$(echo $dir | awk '/ / {print $1}')
        size=$(echo $dir | awk '/ / {print $2}')
        directory=$(echo $dir | awk '/ / {print $3}')

        mysql -u root -D content -e "INSERT INTO dirsearch(status, size, endpoint, program_id, subdomain_id, dir_date) VALUES($status, '$size', '$directory', $p_id, $url_id, now())"
        dir_count=$(($dir_count + 1))


    done <scanner/dirsearch.txt


printf "${GREEN}\n\n[+] $dir_count Directory Inserted Into Database \n\n${NC}"

    

}


<<<<<<< HEAD
=======



function nuclei_scan(){



if [ ! -d "scanner/nuclei" ]; then
    mkdir scanner/nuclei
fi

if [  -f "scanner/nuclei/result.txt" ]; then
    rm scanner/nuclei/result.txt
fi
    
    
    nuclei -u $1 -o scanner/nuclei/result.txt


    nuclei_count=0
    while read result; do

        mysql -u root -D content -e "INSERT INTO nuclei(nuclei_result, program_id, subdomain_id, nuclei_date) VALUES('$result', $p_id, $url_id, now())"
        nuclei_count=$(($nuclei_count + 1))

    done <scanner/nuclei/result.txt

printf "${GREEN}\n\n[+] $nuclei_count Results Inserted into database \n\n${NC}"


}






>>>>>>> 12061c4 (developing Bash Recon project)
function wayback(){

    printf "${ORANGE}[+] Getting Wayback for:\t\t $1 \n\n${NC}"


domain=$(echo $1 |sed 's/https\?:\/\///')

    waybackurls -no-subs $domain >> scanner/wayback
    gau $domain >> scanner/wayback
    gauplus $domain >> scanner/wayback

    cat scanner/wayback | uro | sort -u | tee scanner/wayback.txt
    rm scanner/wayback


    wayback_count=0

    while read wayback_url; do

        check_wayback=$(mysql -u root -D content -N -B -e "SELECT wayback_url FROM wayback WHERE wayback_url='$wayback_url'")
        if [ -z "$check_wayback" ]
        then
            mysql -u root -D content -e "INSERT INTO wayback(wayback_url, program_id, subdomain_id, wayback_date) VALUES(\"$wayback_url\", $p_id, $url_id, now())"
            wayback_count=$(($wayback_count + 1))

        fi

    done <scanner/wayback.txt

printf "${GREEN}\n\n[+] $wayback_count Wayback URL inserted into database \n\n${NC}"


    printf "${ORANGE}[+] Running gf against Wayback Result:\t\t  \n\n${NC}"


    cat scanner/wayback.txt | gf xss > scanner/xss.txt
    cat scanner/wayback.txt | gf sqli > scanner/sqli.txt
    cat scanner/wayback.txt | gf ssrf > scanner/ssrf.txt
    cat scanner/wayback.txt | gf idor > scanner/idor.txt
<<<<<<< HEAD
=======
    cat scanner/wayback.txt | gf lfi > scanner/lfi.txt
>>>>>>> 12061c4 (developing Bash Recon project)
    cat scanner/wayback.txt | gf redirect > scanner/redirect.txt

#------------------------------------------------------------------------------------

xss_count=0
while read xss_url; do

        check_xss=$(mysql -u root -D content -N -B -e "SELECT gf_url FROM gf WHERE gf_url='$xss_url' and gf_pattern='xss' ")
        if [ -z "$check_xss" ]
        then
            mysql -u root -D content -e "INSERT INTO gf(gf_url, gf_pattern, program_id, subdomain_id, gf_date) VALUES(\"$xss_url\", 'xss', $p_id, $url_id, now())"
            xss_count=$(($xss_count + 1))

        fi

done <scanner/xss.txt
printf "${GREEN}\n\n[+] $xss_count XSS Inserted \n\n${NC}"

#------------------------------------------------------------------------------------

sqli_count=0
while read sqli_url; do

        check_sqli=$(mysql -u root -D content -N -B -e "SELECT gf_url FROM gf WHERE gf_url='$sqli_url' and gf_pattern='sqli' ")
        if [ -z "$check_sqli" ]
        then
            mysql -u root -D content -e "INSERT INTO gf(gf_url, gf_pattern, program_id, subdomain_id, gf_date) VALUES(\"$sqli_url\", 'sqli', $p_id, $url_id, now())"
            sqli_count=$(($sqli_count + 1))

        fi

done <scanner/sqli.txt
printf "${GREEN}\n\n[+] $sqli_count SQLI Inserted \n\n${NC}"

#------------------------------------------------------------------------------------

ssrf_count=0
while read ssrf_url; do

        check_ssrf=$(mysql -u root -D content -N -B -e "SELECT gf_url FROM gf WHERE gf_url='$ssrf_url' and gf_pattern='ssrf' ")
        if [ -z "$check_ssrf" ]
        then
            mysql -u root -D content -e "INSERT INTO gf(gf_url, gf_pattern, program_id, subdomain_id, gf_date) VALUES(\"$ssrf_url\", 'ssrf', $p_id, $url_id, now())"
            ssrf_count=$(($ssrf_count + 1))

        fi

done <scanner/ssrf.txt
printf "${GREEN}\n\n[+] $ssrf_count SSRF Inserted \n\n${NC}"

#------------------------------------------------------------------------------------

idor_count=0
while read idor_url; do

        check_idor=$(mysql -u root -D content -N -B -e "SELECT gf_url FROM gf WHERE gf_url='$idor_url' and gf_pattern='idor' ")
        if [ -z "$check_idor" ]
        then
            mysql -u root -D content -e "INSERT INTO gf(gf_url, gf_pattern, program_id, subdomain_id, gf_date) VALUES(\"$idor_url\", 'idor', $p_id, $url_id, now())"
            idor_count=$(($idor_count + 1))

        fi

done <scanner/idor.txt
printf "${GREEN}\n\n[+] $idor_count IDOR Inserted \n\n${NC}"

#------------------------------------------------------------------------------------

redirect_count=0
while read redirect_url; do

        check_redirect=$(mysql -u root -D content -N -B -e "SELECT gf_url FROM gf WHERE gf_url='$redirect_url' and gf_pattern='redirect' ")
        if [ -z "$check_redirect" ]
        then
            mysql -u root -D content -e "INSERT INTO gf(gf_url, gf_pattern, program_id, subdomain_id, gf_date) VALUES(\"$redirect_url\", 'redirect', $p_id, $url_id, now())"
            redirect_count=$(($redirect_count + 1))

        fi

done <scanner/redirect.txt
printf "${GREEN}\n\n[+] $redirect_count REDIRECT Inserted \n\n${NC}"

<<<<<<< HEAD
=======

lfi_count=0
while read lfi_url; do

        check_lfi=$(mysql -u root -D content -N -B -e "SELECT gf_url FROM gf WHERE gf_url='$lfi_url' and gf_pattern='lfi' ")
        if [ -z "$check_lfi" ]
        then
            mysql -u root -D content -e "INSERT INTO gf(gf_url, gf_pattern, program_id, subdomain_id, gf_date) VALUES(\"$lfi_url\", 'lfi', $p_id, $url_id, now())"
            lfi_count=$(($lfi_count + 1))

        fi

done <scanner/lfi.txt
printf "${GREEN}\n\n[+] $lfi_count LFI Inserted \n\n${NC}"

#------------------------------------------------------------------------------------


>>>>>>> 12061c4 (developing Bash Recon project)
}


function crawler(){

    printf "${ORANGE}[+] Crawling Target:\t\t $1 \n\n${NC}"

    echo $1 | hakrawler -t 3 -u | tee scanner/crawler.txt
    

    printf "${ORANGE}[+] Inserting to Database \n\n${NC}"

    crawl_count=0
    while read crawler_url; do

        check_crawl=$(mysql -u root -D content -N -B -e "SELECT crawler_url FROM crawler WHERE crawler_url='$crawler_url'")

        if [ -z "$check_crawl" ]
        then
            mysql -u root -D content -e "INSERT INTO crawler(crawler_url, program_id, subdomain_id, crawler_date) VALUES(\"$crawler_url\", $p_id, $url_id, now())"
            crawl_count=$(($crawl_count + 1))

        fi
    done <scanner/wayback.txt

printf "${GREEN}\n\n[+] $crawl_count Crawl URL Inserted into database \n\n${NC}"

}



<<<<<<< HEAD
while getopts p:u:dwc options; do
=======
while getopts p:u:dwcna options; do
>>>>>>> 12061c4 (developing Bash Recon project)
    case $options in
        p)  

            p_name=$(mysql -u root -D  recon -N -B -e "SELECT p_name FROM program WHERE p_name='$OPTARG'")
            p_id=$(mysql -u root -D  recon -N -B -e "SELECT p_id FROM program WHERE p_name='$OPTARG'")
            if [ -z "$p_name" ]
            then
                echo "This program doesn't exist"
                exit 1
            fi


            ;;


        u)

            url=$(mysql -u root -D recon -N -B -e "SELECT alive FROM live WHERE alive='$OPTARG' and program_id=$p_id")
            url_id=$(mysql -u root -D recon -N -B -e "SELECT live_id FROM live WHERE alive='$OPTARG' and program_id=$p_id")
            if [ -z "$url" ]
            then 
                echo "Unknown url"
                exit 1

            fi

            ;;

        d)


            fuzz "$url"

<<<<<<< HEAD



=======
>>>>>>> 12061c4 (developing Bash Recon project)
            ;;

        w)

            wayback "$url"

            ;;


        c)

            crawler "$url"

<<<<<<< HEAD
=======
            ;;


        n) 
            nuclei_scan "$url"
            ;;
        a)

            fuzz "$url"
            wayback "$url"
            crawler "$url"
            nuclei_scan "$url"

>>>>>>> 12061c4 (developing Bash Recon project)
            
        esac


        
done