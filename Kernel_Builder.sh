#!bin/bash

# Install Required Packages
sudo apt install make bison bc libncurses5-dev tmate git python3-pip curl build-essential zip unzip -y

# Working Directory
WORK_DIR=~/

# Telegram Chat Id
ID="-1001301062160"

# Functions
msg() {
	curl -X POST "https://api.telegram.org/bot$BotToken/sendMessage" -d chat_id="$ID" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
}
file() {
	MD5=$(md5sum "$1" | cut -d' ' -f1)
	curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot$BotToken/sendDocument" \
	-F chat_id="$ID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5</code>"
}

# Cloning Anykernel
git clone --depth=1 https://github.com/iamimmanuelraj/AnyKernel3 $WORK_DIR/Anykernel

# Cloinin Kernel
git clone --depth=1 https://github.com/iamimmanuelraj/android_kernel_xiaomi_jasmine_sprout $WORK_DIR/kernel

# Clone Toolchain
git clone https://github.com/kdrag0n/proton-clang toolchain

# Move to kernel
cd $WORK_DIR/kernel

# Info
DEVICE="Xiaomi Mi A2 (jasmine_sprout)"
DATE=$(TZ=GMT-5:30 date +%d'-'%m'-'%y'_'%I':'%M)
VERSION=$(make kernelversion)
DISTRO=$(source /etc/os-release && echo $NAME)
CORES=$(nproc --all)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT_LOG=$(git log --oneline -n 1)
COMPILER=$($WORK_DIR/toolchains/trb_clang-14/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

#Starting Compilation
msg "<b>========JASMINE Kernel========</b>%0A<b>Hey Immanuel!! Kernel Build Triggered !!</b>%0A<b>Device: </b><code>$DEVICE</code>%0A<b>Kernel Version: </b><code>$VERSION</code>%0A<b>Date: </b><code>$DATE</code>%0A<b>Host Distro: </b><code>$DISTRO</code>%0A<b>Host Core Count: </b><code>$CORES</code>%0A<b>Compiler Used: </b><code>$COMPILER</code>%0A<b>Branch: </b><code>$BRANCH</code>%0A<b>Last Commit: </b><code>$COMMIT_LOG</code>"
BUILD_START=$(date +"%s")
export ARCH=arm64
export SUBARCH=arm64
export PATH="$WORK_DIR/toolchains/bin/:$PATH"
cd $WORK_DIR/kernel
make clean && make mrproper
make O=out jasmine_sprout_defconfig
make -j$(nproc --all) O=out \
      CROSS_COMPILE=aarch64-linux-gnu- \
      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
      CC=clang | tee log.txt

#Zipping Into Flashable Zip
if [ -f out/arch/arm64/boot/Image.gz-dtb ]
then
cp out/arch/arm64/boot/Image.gz-dtb $WORK_DIR/Anykernel
cd $WORK_DIR/Anykernel
zip -r9 JASMINE-$DATE.zip * -x .git README.md */placeholder
cp $WORK_DIR/Anykernel/JASMINE-$DATE.zip $WORK_DIR/
rm $WORK_DIR/Anykernel/Image.gz-dtb
rm $WORK_DIR/Anykernel/JASMINE-$DATE.zip
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

#Upload Kernel

file "$WORK_DIR/JASMINE-$DATE.zip" "Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"

else
file "$WORK_DIR/kernel/log.txt" "Build Failed and took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
fi
