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

if [ ! -d "recon" ]; then

    mkdir recon
fi

   

function recon(){

#-------------------------------------------------------------------
#-------------          Getting Subdomains           ---------------
#-------------------------------------------------------------------

    
printf "${ORANGE}[+] Getting subdomain for $2 & $1 \n\n${NC}"

    amass enum -d $2 -o recon/all_subdomains
    subfinder -d $2 >> recon/all_subdomains
    assetfinder -subs-only $2 >> recon/all_subdomains

    findomain -t $2 -u recon/findomain.txt ; cat recon/findomain.txt >> recon/all_subdomains ; rm recon/findomain.txt

    cat recon/all_subdomains | sort -u | tee recon/all_subdomains.txt


    count=0
    for subdomain in $(cat recon/all_subdomains.txt); do
        
        check_domain=$(mysql -u root -D recon -N -B -e "SELECT subdomain FROM subdomains WHERE subdomain='$subdomain'")
        if [ -z "$check_domain" ]
        then

            mysql -u root -D recon -e "INSERT INTO subdomains(subdomain, basic, program_id, s_date) VALUES('$subdomain', 1, $p_id, now())"
            count=$(($count + 1))
        fi

    done    

printf "${GREEN}\n\n[+] $count Subdomains inserted into database \n\n${NC}"


#-------------------------------------------------------------------
#-------------       Getting Alive Subdomains        ---------------
#-------------------------------------------------------------------

printf "${ORANGE}\n\n[+] Getting Live Subdomains $2 & $1 \n\n${NC}"


    # cat recon/all_subdomains | httpx -nc --status-code -cl >> recon/alive

    cat recon/all_subdomains.txt | httpx -nc --status-code -cl >> recon/alive

    
    sed 's/\[//g' recon/alive | sed 's/\]//g' >> recon/alive.txt 
  
    alive_count=0
    while read domain; do
        url=$(echo $domain | awk '/ / {print $1}')
        status=$(echo $domain | awk '/ / {print $2}')
        size=$(echo $domain | awk '/ / {print $3}')

        check_live=$(mysql -u root -D recon -N -B -e "SELECT alive FROM live WHERE alive='$url'")
        if [ -z "$check_live" ]
        then

            mysql -u root -D recon -e "INSERT INTO live(alive, status, size, is_scanned, program_id, alive_date) VALUES('$url', $status, $size, 0, $p_id, now())"
            alive_count=$(($alive_count + 1))


        fi
    done <recon/alive.txt

printf "${GREEN}\n\n[+] $alive_count Alive URL inserted into database \n\n${NC}"


    rm recon/all_subdomains recon/alive.txt recon/alive

    

}






function bruteforce(){

    printf "${ORANGE}\n\n[+] Testing for bruteforce $2 & $1 \n\n${NC}"

}



#-------------------------------------------------------------------
#-------------          Getting Waybackurls          ---------------
#-------------------------------------------------------------------



function wayback(){

#--------------------------         WAYBACK COMMANDS          ----------------------    

    gau --subs $2 | tee recon/wayback
    waybackurls $2 >> recon/wayback
    gauplus -subs $2 >> recon/wayback


    cat recon/wayback | uro | sort -u | tee recon/wayback.txt

printf "${ORANGE}\n\n[+] Inserting to the Database \n\n${NC}"

#--------------------------         INSERT TO DATABASE          ----------------------    

    wayback_count=0
    while read wayback_url; do
        
        check_wayback=$(mysql -u root -D  recon -N -B -e "SELECT wayback_url FROM waybacks WHERE wayback_url='$wayback_url'")

        if [ -z "$check_wayback" ]
        then

            mysql -u root -D recon -e "INSERT INTO waybacks(wayback_url, program_id, wayback_date) VALUES(\"$wayback_url\", $p_id, now())"
            wayback_count=$(($wayback_count + 1))


        fi
    done <recon/wayback.txt

printf "${GREEN}\n\n[+] $wayback_count Wayback URL inserted into database \n\n${NC}"

    cat recon/wayback | uro | sort -u >> recon/waybacks

    cat recon/waybacks | sort -u >> recon/wayback.txt

    rm recon/wayback recon/waybacks
    


}







while getopts p:d:rwba options; do
    case $options in
        p)  
            # query to check if program already exist in db
            p_name=$(mysql -u root -D  recon -N -B -e "SELECT p_name FROM program WHERE p_name='$OPTARG'")

            if [ -z "$p_name" ]
            then
                mysql -u root -D recon -e "INSERT INTO program(p_name, p_date) VALUES('$OPTARG', now())"


                printf "${GREEN}[+] \t $OPTARG  \t\t Inserting to database.\n${NC}"
                

            else
                printf "${BLUE}[+]${GREEN} \t $p_name ${BLUE} \t\t Program Exist.\n${NC}"

            fi

            program_name=$OPTARG
            ;; 

        d)   

            if [ -z "$program_name" ]
            then
                echo "please, specify program"
            else
                
                p_id=$(mysql -u root -D recon -N -B -e "SELECT p_id FROM program WHERE p_name='$program_name'")
                
                # check if domain already exist

                domain=$(mysql -u root -D recon -N -B -e "SELECT domain FROM domains WHERE domain='$OPTARG'")
                if [ -z "$domain" ]
                then
                    mysql -u root -D recon -e "INSERT INTO domains(domain, program_id, d_date) VALUES('$OPTARG', $p_id, now())"


                    printf "${GREEN}[+] \t $OPTARG  \t\t Inserting to database.\n${NC}"


                else

                    printf "${BLUE}[+]${GREEN} \t $domain ${BLUE} \t\t Domain Exist.\n${NC}"

                fi

                domain_name=$OPTARG

            fi
        
            ;;

        r)
            recon "$program_name" "$domain_name"
        ;;

        w)
            wayback "$program_name" "$domain_name"
            
        ;;



        b)

            bruteforce "$program_name" "$domain_name"

        ;;

        a)

            recon "$program_name" "$domain_name"
            wayback "$program_name" "$domain_name"


        # \?) echo -e "Please provide \n-a for all \n-w for wayback \n-r for recon ";;
        
    esac
done
