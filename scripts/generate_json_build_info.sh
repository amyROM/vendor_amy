#!/bin/sh
if [ "$1" ]
then
  file_path=$1
  file_name=$(basename "$file_path")
  DEVICE=$(echo $TARGET_PRODUCT | cut -d "_" -f2)
  if [ -f $file_path ]; then
    file_size=$(stat -c%s $file_path)
    id=$(cat "$file_path.sha256sum" | cut -d' ' -f1)
    datetime=$(grep ro\.build\.date\.utc ./out/target/product/$DEVICE/system/build.prop | cut -d= -f2);
    rom_version=$(grep ro\.lineage\.version ./out/target/product/$DEVICE/system/build.prop | cut -d= -f2 | cut -d "v" -f2);
    custom_build_type=$(grep ro\.lineage\.releasetype ./out/target/product/$DEVICE/system/build.prop | cut -d= -f2);
    echo "{\n  \"response\": [\n    {\n      \"datetime\": $datetime,\n      \"filename\": \"$file_name\",\n      \"id\": \"$id\",\n      \"romtype\": \"$custom_build_type\",\n      \"size\": $file_size,\n      \"url\": \"https://sabina.amyrom.tech/ota/reborn/$DEVICE/$file_name\",\n      \"version\": \"$rom_version\"\n    }\n  ]\n}" > $file_path.json
    echo "OTA JSON: $file_path.json"
  fi
fi
