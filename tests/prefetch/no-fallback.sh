#! /usr/bin/env bash

: "${RUN_PREFETCH:=${BASH_SOURCE[0]%/*}/run-prefetch.sh}";

URL='https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz';
EXPECT_TYPE='tarball';

export URL EXPECT_TYPE;
$RUN_PREFETCH;
