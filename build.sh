#!/bin/bash

echo
echo "--------------------------------------"
echo "        exthmUI 14.0 Buildbot         "
echo "            by qssn70                 "
echo "        based on kindle4jerry         "
echo "--------------------------------------"
echo

set -e

BL=$PWD/treble_build_exthm
BD=$HOME/builds

initRepos() {
    if [ ! -d .repo ]; then
        echo "--> Initializing workspace"
        repo init -u https://github.com/exTHmUI/android -b Utsuho --depth=1
        echo "--> Initializing workspace done"

        echo "--> Preparing local manifest"
        mkdir -p .repo/local_manifests
        cp $BL/manifest.xml .repo/local_manifests/exthm.xml
        echo "--> Preparing local manifest done"
		
	echo
    fi
}

syncRepos() {
	echo "--> Syncing repos"
	repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
	
	#restart sync when  failed
	while [ $? -ne 0 ];
	do
	echo              "!!error!! sync failed!"
	echo "It will be restarted automatically after 3 seconds."
	sleep 3s
	repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
	done
	
	echo "--> Syncing repos dones"
	
	echo
}

applyPatches() {
echo "--> Creating config files"
cd device/phh/treble
cp $BL/Android.bp bluetooth/audio
cp -frp $BL/hw/Android.bp bluetooth/audio/hw
cp -frp $BL/utils/Android.bp bluetooth/audio/utils
cp $BL/exthm.mk .
bash generate.sh exthm
cd ../../..
echo "--> Creating config files done"

patches="$(readlink -f -- $BL)"
tree_ext="TrebleDroid
personal
"
for tree in $tree_ext;
do
	echo "--> Applying $tree patches"
	for project in $(cd $patches/patches/$tree; echo *);
		do
		p="$(tr _ / <<<$project |sed -e 's;platform/;;g')"
		[ "$p" == build ] && p=build/make
		[ "$p" == treble/app ] && p=treble_app
		[ "$p" == vendor/hardware/overlay ] && p=vendor/hardware_overlay
		pushd $p &>/dev/null
		for patch in $patches/patches/$tree/$project/*.patch; do
			del=(find .repo -name rebase-apply -type d)
			for cut in $del;
			do
			rm -rf $cut
			done
			git am $patch || true
		done
		popd
	done
	echo "--> Applying $tree patches done"
done

echo
}

setupEnv() {
    echo "--> Setting up build environment"
    source build/envsetup.sh &>/dev/null
    mkdir -p $BD
    echo "--> Setting up build environment done"
	
    echo
}

buildTrebleApp() {
    echo "--> Building treble_app"
    cd treble_app
    bash build.sh release
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
    echo "--> Building treble_app done"
	
    echo
}

buildVariant() {
    echo "--> Building treble_arm64_bvN"
    lunch treble_arm64_bvN-userdebug
    make -j$(nproc --all) installclean
    make -j$(nproc --all) systemimage
    mv $OUT/system.img $BD/system-treble_arm64_bvN.img
    echo "--> Building treble_arm64_bvN done"
	
    echo
}

buildSlimVariant() {
    echo "--> Building treble_arm64_bvN-slim"
    (cd vendor/exthm && git am $BL/patches/slim.patch)
    make -j$(nproc --all) systemimage
    (cd vendor/exthm && git reset --hard HEAD~1)
    mv $OUT/system.img $BD/system-treble_arm64_bvN-slim.img
    echo "--> Building treble_arm64_bvN-slim done"
	
    echo
}

buildVndkliteVariant() {
    echo "--> Building treble_arm64_bvN-vndklite"
    cd sas-creator
    sudo bash lite-adapter.sh 64 $BD/system-treble_arm64_bvN.img
    cp s.img $BD/system-treble_arm64_bvN-vndklite.img
    sudo rm -rf s.img d tmp
    cd ..
    echo "--> Building treble_arm64_bvN-vndklite done"
	
    echo
}

generatePackages() {
    echo "--> Generating packages"
    xz -cv $BD/system-treble_arm64_bvN.img -T0 > $BD/exthmUI_arm64-ab-7.6-unofficial-$BUILD_DATE.img.xz
#    xz -cv $BD/system-treble_arm64_bvN-vndklite.img -T0 > $BD/exthmUI_arm64-ab-vndklite-7.6-unofficial-$BUILD_DATE.img.xz
#    xz -cv $BD/system-treble_arm64_bvN-slim.img -T0 > $BD/exthmUI_arm64-ab-slim-7.6-unofficial-$BUILD_DATE.img.xz
    rm -rf $BD/system-*.img
    echo "--> Generating packages done"
	
    echo
}

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

initRepos
syncRepos
applyPatches
setupEnv
buildSTrebleApp
buildVariant
#buildSlimVariant
#buildVndkliteVariant
generatePackages

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
