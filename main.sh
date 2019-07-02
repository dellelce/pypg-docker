#!/bin/bash
#
# File:         main.sh
# Created:      110918
#
# invoke docker build & push
#

### FUNCTIONS ###

 docker_hub_login()
 {
  [ -z "$DOCKER_PASSWORD" -o -z "$DOCKER_USERNAME" ] && { echo "docker_hub: Docker environment not set-up correctly"; return 1; }
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  rc=$?
  [ $rc -ne 0 ] && { echo "docker_hub: Docker hub login failed with rc = $rc"; return $rc; }

  return 0
 }

### ENV ###

 image="${1:-${TARGET_IMAGE}}"; shift
 image="${image:-dellelce/pypg-client}" # if still not set use "dellelce/client"

 prefix="${1:-${PREFIX}}"; shift
 prefix="${prefix:-/app/pg}" # sanity check

 # make sure the base_image is set if not use our default image with a basic PG install
 base_image="${BASE_IMAGE:-dellelce/pgbase}"

### MAIN ###

 docker build -t "$image" --build-arg BASE=$base_image --build-arg PREFIX=$prefix .
 build_rc="$?"
 [ $build_rc -eq 0 -a ! -z "$image" ] &&
 {
   docker_hub_login || exit $?

   py_version=$(docker run -it --rm "$image" python3 -V | awk ' { printf $2 } ' | sed -e 's/\r//g')
   pypg_version=$(docker run -it --rm "$image" pip3 list | awk ' /psycopg2/ {printf "%s", $2 } ' | sed -e 's/\r//g')

   # build image list
   images="$image $image:${pypg_version} $image:${pypg_version}-py${py_version}"

   docker tag "$image" "$image:${pypg_version}"
   docker tag "$image" "$image:${pypg_version}-py${py_version}"

   for target in $images
   do
     docker push "$target" || exit $?
   done
   exit 0
 }

 exit $build_rc

### EOF ###
