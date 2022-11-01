#! /usr/bin/env bash

: "${RUN_PREFETCH:=${BASH_SOURCE[0]%/*}/run-prefetch.sh}";

URL='https://registry.npmjs.org/char-regex/-/char-regex-1.0.2.tgz';
EXPECT_TYPE='file';

export URL EXPECT_TYPE;
$RUN_PREFETCH;
