#!/bin/sh

# When Images.xcassets is compiled it creates 3 pngs from wmf_logo.pdf
# This script copies those files to the "assets/images/" folder

target_path="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
assets_path="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/assets/images/"

cp -v $target_path"WMFLogo_60.png" $assets_path"wmflogo_60.png"
cp -v $target_path"WMFLogo_60@2x.png" $assets_path"wmflogo_120.png"
cp -v $target_path"WMFLogo_60@3x.png" $assets_path"wmflogo_180.png"