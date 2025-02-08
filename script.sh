!#/bin/bash

# Usage: ./script.sh <domain>
set -e

DOMAIN="$1"
echo "Starting recon on domain $DOMAIN"

# Downloading http_port_scanner script
wget "https://gist.githubusercontent.com/merbinr/74718967462b662ff04be9a02e74618a/raw/d476610d01c8403a7ee2c0a4b2b9715600184be7/http_port_scanner.py"

# Downloading duplicate filter script
wget "https://gist.githubusercontent.com/merbinr/ae66507250c5fdf7bd05bb857171ddbf/raw/f6f7a81b7095c12ccfa57bf2461556e4c13a3c97/filter_duplicate_http.py"

# Downloading nuclei templates
wget "https://gist.githubusercontent.com/merbinr/25217b985478efdafa4fd4ef5c2a034c/raw/17a2249863d1460494b86c1f56e24dc24ed85cd0/swagger_nuclei.yaml"

# Downloading JS file downloader
wget "https://gist.githubusercontent.com/merbinr/63488eb36fc97cf250b4d66221f619de/raw/5333187a95115a6cdc8b6bc6d3deb46d04dd3e14/download_js_files.py"

# Downloading endpoints scraper
wget "https://gist.githubusercontent.com/merbinr/c34fa7bd5af2a4044253a6c354d7d923/raw/9c7be666e48da97315283e078503b85c960cab02/endpoints_scraper.py"

# Downloading waybackurls deduper
wget "https://gist.githubusercontent.com/merbinr/8ce68f28264b0aff2ccc52b74a1c2a4c/raw/d4d0090d3e22c3d59491f33ce503319934576cc2/waybackurl_deduper.py"

subfinder -d $DOMAIN -o subdomains.txt -config ~/.config/subfinder/config.yaml

# Downloading wayback urls
curl "https://web.archive.org/cdx/search/cdx?url=*.$DOMAIN/*&output=text&fl=original&collapse=urlkey&filter=statuscode:200" > wayback_urls.txt

python3 waybackurl_deduper.py -i wayback_urls.txt > wayback_urls_deduped.txt

python3 http_port_scanner.py -i subdomains.txt -p 0-65535 > live_sites.txt

python3 filter_duplicate_http.py -i live_sites.txt -o filtered_live_sites.txt

nuclei -l filtered_live_sites.txt -t swagger_nuclei.yaml -o nuclei_output.txt

getJS -input filtered_live_sites.txt -complete -output js_finder.txt

cat js_finder.txt  wayback_urls.txt | grep $DOMAIN | grep -E "\.js$|\.js\?" | sort -u  >  js_urls_file.txt

python3 download_js_files.py -i js_urls_file.txt -o js_file_output -t 5

python3 endpoints_scraper.py -i js_file_output -o endpoints_from_js.txt

# Cleaning up all scripts
rm -rf *.py
