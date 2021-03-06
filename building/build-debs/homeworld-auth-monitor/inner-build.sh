#!/bin/bash
set -e -u

GO_VER=1.9.3

rm -rf go
tar -xf "go-bin-${GO_VER}.tgz" go/
export GOROOT="$(pwd)/go/"
export PATH="$PATH:$GOROOT/bin"

if [ "$(go version 2>/dev/null)" != "go version go${GO_VER} linux/amd64" ]
then
	echo "go version mismatch! expected ${GO_VER}" 1>&2
	go version 1>&2
	exit 1
fi

PROMETHEUS_VER="2.0.0"
PROMETHEUS_CLIENT_GOLANG_VER="0.9.0-pre1"

rm -f src/github.com
rm -rf src/gopkg.in
rm -rf src/golang.org
rm -rf "prometheus-${PROMETHEUS_VER}"
tar -xf "golang-x-crypto.tar.xz" src/golang.org
tar -xf "gopkg.in-yaml.v2.tar.xz" src/gopkg.in
tar -xf "prometheus-${PROMETHEUS_VER}.tar.xz" "prometheus-${PROMETHEUS_VER}/vendor"
tar -xf "prometheus-client_golang-${PROMETHEUS_CLIENT_GOLANG_VER}.tar.xz" "client_golang-${PROMETHEUS_CLIENT_GOLANG_VER}"
rm -rf "prometheus-${PROMETHEUS_VER}/vendor/github.com/prometheus/client_golang/"
mv "client_golang-${PROMETHEUS_CLIENT_GOLANG_VER}" -T "prometheus-${PROMETHEUS_VER}/vendor/github.com/prometheus/client_golang/"
ln -s "../prometheus-${PROMETHEUS_VER}/vendor/github.com" src/github.com

export GOPATH="$(pwd)"
(cd src && go build -o ../auth-monitor auth-monitor.go)

echo "auth-monitor built!"
