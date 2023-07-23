#!/bin/bash

timeout=10;

mkdir -p ./tmp

# Italian regions dictionary
declare -A IR

# Italian regions IDs (OSM IDs are not permanent)
IR[Sicily]=3600039152
IR[Sardinia]=3607361997
IR[Tuscany]=3600041977
IR[Lazio]=3600040784
IR[Umbria]=3600042004
IR[Marche]=3600053060
IR[Abruzzo]=3600053937
IR[Apulia]=3600040095
IR[Calabria]=3601783980
IR[Basilicata]=3600040137
IR[Campania]=3600040218
IR[Molise]=3600041256
IR[Piedmont]=3600044874
IR[Emilia-Romagna]=3600042611
IR[Lombardy]=3600044879
IR[Liguria]=3600301482
IR[Aosta_Valley]=3600045155
IR[Veneto]=3600043648
IR[Trentino-Alto_Adige]=3600045757
IR[Friuli-Venezia_Giulia]=3600179296

if [ "$#" -ne 1 -o -z "${IR[$1]}" ]; then
	echo "Usage: $0 <italian region>"
 	echo "Where Italian region is one of the following:"
  	for el in "${!IR[@]}"; do
   		echo "$el";
   	done
        exit -1
fi

# current Italian Region
cur_IR="${IR[$1]}"

# website tag
curl "https://overpass-api.de/api/interpreter?data=%5Bout%3Acsv%28%3A%3Atype%2C%3A%3Aid%2Cwebsite%29%5D%5Btimeout%3A25%5D%3B%0Aarea%28id%3A${cur_IR}%29-%3E.searchArea%3B%0Anwr%5B%22website%22%5D%28area.searchArea%29%3B%0Aout%20meta%3B" >./tmp/"$1"_elements_website.lst

# contact:website tag
curl "https://overpass-api.de/api/interpreter?data=%5Bout%3Acsv%28%3A%3Atype%2C%3A%3Aid%2C%22contact:website%22%3Bfalse%29%5D%5Btimeout%3A25%5D%3B%0Aarea%28id%3A${cur_IR}%29-%3E.searchArea%3B%0Anwr%5B%22contact:website%22%5D%28area.searchArea%29%3B%0Aout%20meta%3B" >>./tmp/"$1"_elements_website.lst

# url tag
curl "https://overpass-api.de/api/interpreter?data=%5Bout%3Acsv%28%3A%3Atype%2C%3A%3Aid%2Curl%3Bfalse%29%5D%5Btimeout%3A25%5D%3B%0Aarea%28id%3A${cur_IR}%29-%3E.searchArea%3B%0Anwr%5B%22url%22%5D%28area.searchArea%29%3B%0Aout%20meta%3B" >>./tmp/"$1"_elements_website.lst


awk -F'\t' 'NR>1{if (NF>3) {website=$3; for (f=4;f<=NF;f++) website = website FS $f} else {website=$3}; n = split($NF,w,";"); for (i=1;i<=n;i++) print w[i]}' ./tmp/"$1"_elements_website.lst | sort | uniq | \
	parallel 'website=$(echo {} | sed '\''s/^ *"\?\|"\? *$//g'\''); if [[ ! ( "$website" =~ ^https?:// ) ]]; then res=-1; HTTP_CODE=;location=; else read res HTTP_CODE location < <({ curl -m "'"$timeout"'" -sI "$website"; echo $?; } | awk '\''NR==1{http_code=$2} /^[Ll]ocation:/{loc=$2} END{print $1, http_code, loc}'\''); fi; echo -e "$website\t$res\t$HTTP_CODE\t$location"' > ./tmp/"$1"_websites_checked.lst
	

while IFS=$'\t' read website res HTTP_CODE location; do	
	osm_url_list=$(awk -F'\t' -v ref="$website" '{n = split($3,w,";"); for (i=1;i<=n;i++) { gsub(/^ *?"|"? *$/,"", w[i]); if  (w[i] == ref) { if (!out) out="https://osm.org/browse/" $1 "/" $2; else out= out " https://osm.org/browse/" $1 "/" $2 }; next; } } END{print out}' ./tmp/"$1"_elements_website.lst);

	case $res in
       -1)
                echo "MISSING_URI_SCHEME $osm_url_list $website";;
	3)
		echo "NOT_URL $osm_url_list $website";;
	6)
		echo "COULD_NOT_RESOLVE_HOST $osm_url_list $website";;
	7)
		echo "FAILED_TO_CONNECT_TO_HOST $osm_url_list $website";;
	28)
		echo "TIMEOUT $osm_url_list $website";;
	35)
		echo "SSL_CONNECT_ERROR $osm_url_list $website";;
	60)
		echo "PEER_CERTIFICATE_FROM_UNKNOWN_CA_CERTIFICATES $osm_url_list $website";;

	0)
		case $HTTP_CODE in
			1*)
				echo "INFORMATION_(100…199) $HTTP_CODE $osm_url_list $website";;
			2*)
				echo "SUCCESS_(200…299) $HTTP_CODE $osm_url_list $website";;
			3*)
				if [[ "$location" =~ https?:// ]]; then
					echo "REDIRECTION_(300…399) $HTTP_CODE $osm_url_list $website → $location"
				else
					echo "SAME_DOMAIN_REDIRECTION_(300…399) $HTTP_CODE $osm_url_list $website → $location"
				fi;;
					
			4*)
				echo "CLIENT_ERROR_(400…499) $HTTP_CODE $osm_url_list $website";;
			5*)
				echo "SERVER_ERROR_(500…599) $HTTP_CODE $osm_url_list $website";;
			*)
				echo "WEIRD_HTTP_RESPONSE $HTTP_CODE $osm_url_list $website";;
			esac;;
	*)
		echo "OTHER_CURL_ERROR $res $HTTP_CODE $osm_url_list $website";;
	esac
		
done <./tmp/"$1"_websites_checked.lst
