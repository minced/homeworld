#!/bin/bash

##
## build .deb and .rpm packages from an already-built
## version of rkt

set -e
set -x

version=$1

MAINTAINER=sipb-hyades-root@mit.edu
LICENSE="APLv2"
VENDOR="MIT SIPB Hyades Project"
HOMEPAGE="https://www.github.com/rkt/rkt"
#iteration is the package version; bump if you need to repackage without
#changing the rkt version
ITERATION="${ITERATION:-1}" 
builddir="${BUILDDIR:-/opt/build-rkt}"

function usage {
    echo "usage: BUILDDIR=<builddir> $0 <version>" >&2 
    exit 1
}

if [ ! -d "$builddir" ]; then
    echo "could not find build dir $builddir" >&2
    usage
fi

if [ -z "$version" ]; then
    echo "version not specified" >&2
    usage
fi

srcdir=$(dirname "$0")/rkt-${version}/scripts/pkg/
projectdir=$srcdir/../..

###################################
## INSTALL RKT
#################################
workdir=$(mktemp -d /tmp/rkt-pkg.XXXXXX)
prefix=$workdir/rootfs
mkdir -p "$prefix"

## install binary
install -Dm755 "$builddir/target/bin/rkt" "$prefix/usr/bin/rkt"

## install stage1s
for flavor in coreos kvm; do
    install -Dm644 "$builddir/target/bin/stage1-${flavor}.aci" "$prefix/usr/lib/rkt/stage1-images/stage1-${flavor}.aci"
done

## manpages & doc
# for f in $projectdir/dist/manpages/*; do 
#     install -Dm644 -t $prefix/usr/share/man/man1 "${f}" 
# done

# for dir in . subcommands networking performance; do
#     for f in $projectdir/Documentation/$dir/*.*; do
#         install -Dm644 -t $prefix/usr/share/doc/rkt "${f}"
#     done
# done

# install -Dm644 "$projectdir/dist/bash_completion/rkt.bash" "$prefix/usr/share/bash-completion/completions/rkt"
install -Dm644 "$projectdir/dist/init/systemd/tmpfiles.d/rkt.conf" "$prefix/usr/lib/tmpfiles.d/rkt.conf"

for unit in rkt-gc.{timer,service} rkt-metadata.{socket,service} rkt-api{.service,-tcp.socket}; do
    install -Dm644 -t "$prefix/usr/lib/systemd/system/"  "$projectdir/dist/init/systemd/${unit}"
done

## Copy before and after-install
cp "$srcdir"/*-{install,remove} "$workdir/"


#######################
## BUILD THE PACKAGES
#######################
cd "$builddir/target/bin"
fpm -s dir -t deb \
    -n "hyades-rkt" -v "$version" --iteration "$ITERATION" \
    --after-install "$workdir/after-install" \
    --before-install "$workdir/before-install" \
	--after-remove "$workdir/after-remove" \
	--before-remove "$workdir/before-remove" \
	--after-upgrade "$workdir/after-install" \
	--before-upgrade "$workdir/before-remove" \
    --license "$LICENSE" --vendor "$VENDOR" --url "$HOMEPAGE" -m "$MAINTAINER" --category utils \
    -d adduser \
    -d dbus \
    -d libc6 \
    -d systemd \
    -d iptables \
    --deb-suggests ca-certificates \
    -C "${prefix}"

rm -rf "$workdir"
