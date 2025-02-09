autoInstallDependencies() {
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        distro=$(awk -F= '$1 == "ID" {print $2}' /etc/os-release)
        id_like=$(awk -F= '$1 == "ID_LIKE" {print $2}' /etc/os-release)
        if [[ "$distro" == "arch" || "$id_like" == "arch" ]]; then
            echo "$ARCH_LINUX"
            git clone https://github.com/akhilnarang/scripts $BD/builds
            cd $BD/scripts
            bash setup/arch-manjaro.sh
            cd $ND
        else
            echo "$password" | sudo -S apt-get update
            echo "$password" | sudo -S apt-get install bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev xattr openjdk-11-jdk jq android-sdk-libsparse-utils python3 python2 repo -y
        fi
    fi
}
autoInstallDependencies
