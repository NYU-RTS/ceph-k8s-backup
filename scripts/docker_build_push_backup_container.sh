#!/bin/sh

set -eu

cd "$(dirname "$0")"
cd ..

VERSION=$(git describe | sed 's/^v//')
IMAGE=ghcr.io/nyu-its/ceph-k8s-backup/restic:$VERSION

docker buildx build --pull \
    - \
    --cache-from type=registry,ref=ghcr.io/remram44/ceph-k8s-backup/restic-buildxcache \
    --cache-to type=registry,mode=max,ref=ghcr.io/remram44/ceph-k8s-backup/restic-buildxcache,oci-mediatypes=false \
    --platform linux/amd64,linux/arm64 \
    --push --tag $IMAGE \
    < backup-container.dockerfile

echo
echo "    $IMAGE"
