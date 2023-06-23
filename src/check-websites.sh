#!/bin/bash

timeout=10;

mkdir -p ./tmp

# Tuscany
curl "https://overpass-api.de/api/interpreter?data=%5Bout%3Acsv%28%3A%3Atype%2C%3A%3Aid%2Cwebsite%3Btrue%3B%22%20%22%29%5D%5Btimeout%3A25%5D%3B%0Aarea%28id%3A3600041977%29-%3E.searchArea%3B%0Anwr%5B%22website%22%5D%28area.searchArea%29%3B%0Aout%20meta%3B" >./tmp/elements_website.lst
awk 'NR>1{print $NF}' ./tmp/elements_website.lst | sort | uniq | \
	parallel 'read website <<<{}; if [ ${website:0:1} = "\"" ]; then website=${website:1:-1}; fi; read res HTTP_CODE location < <({ curl -m "'"$timeout"'" -sI "$website"; echo $?; } | awk '\''NR==1{http_code=$2} /^[Ll]ocation:/{loc=$2} END{print $1, http_code, loc}'\''); echo "$website $res $HTTP_CODE $location"' > ./tmp/websites_checked.lst
	

while read website res HTTP_CODE location; do	
	osm_url_list=$(awk -v ref="$website" '$3 == ref {if (!out) out="https://osm.org/browse/" $1 "/" $2; else out= out " https://osm.org/browse/" $1 "/" $2} END{print out}' ./tmp/elements_website.lst); 

	case $res in
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
		
done <./tmp/websites_checked.lst
