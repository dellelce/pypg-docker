#!/bin/bash
#
# File:         main.sh
# Created:      110918
#
# invoke docker build & push
#

### FUNCTIONS ###

 docker_hub()
 {
  typeset target="$1"

  [ -z "$DOCKER_PASSWORD" -o -z "$DOCKER_USERNAME" ] && { echo "docker_hub: Docker environment not set-up correctly"; return 1; }
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  rc=$?
  [ $rc -ne 0 ] && { echo "docker_hub: Docker hub login failed with rc = $rc"; return $rc; }

  [ ! -z "$target" ] && { docker push "$target"; return $?; }
  return 0
 }

### ENV ###

 image="${1:-${TARGET_IMAGE}}"; shift

 prefix="${1:-${PREFIX}}"; shift
 prefix="${prefix:-/app/pg}" # sanity check

### MAIN ###

 docker build -t "$image" --build-arg BASE=$BASE_IMAGE --build-arg PREFIX=$prefix .
 build_rc="$?"
 [ $build_rc -eq 0 -a ! -z "$image" ] && { docker_hub "$image"; exit $?; }
 exit $build_rc

### EOF ###
