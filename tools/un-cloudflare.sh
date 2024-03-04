#!/usr/bin/env bash
# Remove cloudflare instances from services-full.json

tmpfile="out.json"
infile="${1:-services-full.json}"
outfile="${2:-services.json}"

rm -f "${tmpfile}"

while read -r line; do
    if [[ "$line" == "\"https://"* ]]; then
        domain=$(echo "$line" | sed -e "s/^\"https:\/\///" -e "s/\",//" -e "s/\"//" | awk -F  '|' '{print $1}')
        ips=$(dig "$domain" +short || true)
        cf=0
        echo "$domain"

        for ip in $ips
        do
            echo "    - $ip"
            resp=$(curl --connect-timeout 5 --max-time 5 -s "$ip")

            # Cloudflare does not allow accessing sites using their IP,
            # and returns a 1003 error code when attempting to do so. This
            # allows us to check for sites using Cloudflare for proxying,
            # rather than just their nameservers.
            if [[ "$resp" == *"error code: 1003"* ]]; then
                cf=1
                echo "    ! Using cloudflare proxy, skipping..."
                break
            fi
        done

        if [ $cf -eq 0 ]; then
            echo "$line" >> "${tmpfile}"
        fi
    else
        echo "$line" >> "${tmpfile}"
    fi
done <$infile

# Remove any trailing commas from new instance lists
sed -i -e ':begin' -e '$!N' -e 's/,\n]/\n]/g' -e 'tbegin' -e 'P' -e 'D' "${tmpfile}"

cat "${tmpfile}" | jq --indent 2 . > "${outfile}"
rm -f "${tmpfile}"
