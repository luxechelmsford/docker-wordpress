#!/bin/bash

function test2 () {
  if [ -f "./apps/configs/site-common.env" ]; then
    . ./apps/configs/site-common.env
  fi
  SITE_NAME="demo"
  if [ -f "./apps/configs/site-${SITE_NAME}.env" ]; then
    . ./apps/configs/site-demo.env
  fi
 echo Test2 $SITE_ADMIN
}


function test1 () {
 echo Test1 $SITE_ADMIN
}

unset SITE_ADMIN
test1
unset SITE_ADMIN
test2
unset SITE_ADMIN
test1
