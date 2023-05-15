#! /usr/bin/env bash

: "${RUN_PREFETCH:=${BASH_SOURCE[0]%/*}/run-prefetch.sh}";

URL='https://registry.npmjs.org/char-regex/-/char-regex-1.0.2.tgz';
#case "$( ${NIX:-nix} --version|${CUT:-cut} -d' ' -f3; )" in
#  2.12.*|2.11.*|2.10.*|2.[0-9].*) EXPECT_TYPE='file'; ;;
#  2.1*)                           EXPECT_TYPE='tarball'; ;;
#  *)                              EXPECT_TYPE='file'; ;;
#esac

EXPECT_TYPE=tarball;

export URL EXPECT_TYPE;
$RUN_PREFETCH;
