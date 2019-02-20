#!/usr/bin/env bash
set -e

echo "Setting permissions ..."

dirs=(
 "${PUBLIC_PATH}/wp-content/themes/planet4-master-theme/languages" \
 "${PUBLIC_PATH}/wp-content/themes/planet4-plugin-blocks/languages" \
)

suffixes=(
  "pot"
  "po"
  "mo"
)

for d in "${dirs[@]}"
do
  echo "Setting permissions in $d ..."

  [ ! -d "$d" ] && {
    >&2 echo "WARNING: Directory not found: $d"
    continue
  }

  ls -al "$d"

  for s in "${suffixes[@]}"
  do
    echo " - *.$s : $(find "$d" -type f -name "*.$s" | wc -l) files"
    find "$d" -type f -name "*.$s" -exec chmod 644 {} +
  done

done
