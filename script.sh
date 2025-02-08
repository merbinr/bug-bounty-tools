#!/bin/bash

# Usage: ./script.sh <domain>
set -e

DOMAIN="$1"
echo "Starting recon on domain $DOMAIN"

if [ ! -f "http_port_scanner.py" ]; then
    # Downloading http_port_scanner script
    wget "https://gist.githubusercontent.com/merbinr/74718967462b662ff04be9a02e74618a/raw/3995769dfffd43afa63e57580463aa6572ac7047/http_port_scanner.py"
fi


if [ ! -f "filter_duplicate_http.py" ]; then
    # Downloading duplicate filter script
    wget "https://gist.githubusercontent.com/merbinr/ae66507250c5fdf7bd05bb857171ddbf/raw/f6f7a81b7095c12ccfa57bf2461556e4c13a3c97/filter_duplicate_http.py"
fi

if [ ! -f "swagger_nuclei.yaml" ]; then
    # Downloading nuclei templates
    wget "https://gist.githubusercontent.com/merbinr/25217b985478efdafa4fd4ef5c2a034c/raw/17a2249863d1460494b86c1f56e24dc24ed85cd0/swagger_nuclei.yaml"
fi

if [ ! -f "download_js_files.py" ]; then
    # Downloading JS file downloader
    wget "https://gist.githubusercontent.com/merbinr/63488eb36fc97cf250b4d66221f619de/raw/5333187a95115a6cdc8b6bc6d3deb46d04dd3e14/download_js_files.py"
fi

if [ ! -f "endpoints_scraper.py" ]; then
    # Downloading endpoints scraper
    wget "https://gist.githubusercontent.com/merbinr/c34fa7bd5af2a4044253a6c354d7d923/raw/9c7be666e48da97315283e078503b85c960cab02/endpoints_scraper.py"
fi

if [ ! -f "waybackurl_deduper.py" ]; then
    # Downloading waybackurls deduper
    wget "https://gist.githubusercontent.com/merbinr/8ce68f28264b0aff2ccc52b74a1c2a4c/raw/d4d0090d3e22c3d59491f33ce503319934576cc2/waybackurl_deduper.py"
fi

if [ ! -f "subdomains.txt" ]; then
    subfinder -d $DOMAIN -o subdomains.txt -config ~/.config/subfinder/config.yaml
fi

if [ ! -f "wayback_urls.txt" ]; then
    # Downloading wayback urls
    curl "https://web.archive.org/cdx/search/cdx?url=*.$DOMAIN/*&output=text&fl=original&collapse=urlkey&filter=statuscode:200" > wayback_urls.txt
fi

if [ ! -f "wayback_urls_deduped.txt" ]; then
    python3 waybackurl_deduper.py -i wayback_urls.txt > wayback_urls_deduped.txt
fi

if [ ! -f "live_sites.txt" ]; then
    python3 http_port_scanner.py -i subdomains.txt -p 3000,5000,5001,7000,7474,8000,8001,8008,8080,8081,8088,8090,8091,8333,8443,8880,8888,9000,9001,9043,9090,9091,9100,9200,9443,9800,12443,16080,18091,18092,20720,28017,45001,4433,6443,8009,8082,9040,9300,9990,27017,5984,5601,4000,8089,8800,9443,9080,7001,7002,8010,80,443 > live_sites.txt
fi

if [ ! -f "filtered_live_sites.txt" ]; then
    python3 filter_duplicate_http.py -i live_sites.txt -o filtered_live_sites.txt
fi

if [ ! -f "nuclei_output.txt" ]; then
    nuclei -l filtered_live_sites.txt -t swagger_nuclei.yaml -o nuclei_output.txt
fi

if [ ! -f "js_finder.txt" ]; then
    getJS -input filtered_live_sites.txt -complete -output js_finder.txt
fi

if [ ! -f "js_urls_file.txt" ]; then
    cat js_finder.txt  wayback_urls.txt | grep $DOMAIN | grep -E "\.js$|\.js\?" | sort -u  >  js_urls_file.txt
fi

if [ ! -d "js_file_output" ]; then
python3 download_js_files.py -i js_urls_file.txt -o js_file_output -t 5
fi

if [ ! -f "endpoints_from_js.txt" ]; then
    python3 endpoints_scraper.py -i js_file_output -o endpoints_from_js.txt
fi

# Cleaning up all scripts
rm -rf *.py
