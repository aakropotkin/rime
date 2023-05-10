# ============================================================================ #
#
# Allows locked inputs to be referenced without evaluating the flake which owns
# the lockfile.
#
# NOTE: This file may be dropped into any directory containing a `flake.lock'.
#
# ---------------------------------------------------------------------------- #
#
# Importing this file for use in other Nix expressions is trivial, but the
# examples below cover usage from the Nix CLI.
#
# ---------------------------------------------------------------------------- #
#
# Example: Print URIs usable by `builtins.getFlake' and Nix CLI tools.
#
# $ nix eval --json -f inputs.nix|jq;
# {
#   "ak-nix": "github:aakropotkin/ak-nix/123fc484c3c68e354704c86a88d88e343e6371f3",
#   "at-node-nix": "github:aameen-tulip/at-node-nix/ef7cc7ef572f50e537739706668aadb9029d5d1e",
#   "laika": "github:aakropotkin/laika/5b8eb6aab5f9eb2b4f9d93f40bb75ab7d0f5127c",
#   "nixpkgs": "github:NixOS/nixpkgs/95aeaf83c247b8f5aa561684317ecd860476fcd6",
#   "nixpkgs_2": "github:NixOS/nixpkgs/95aeaf83c247b8f5aa561684317ecd860476fcd6",
#   "rime": "github:aakropotkin/rime/b7440e737b5e43b99a88dd192f469d4d9d419b7f"
# }
#
#
# ---------------------------------------------------------------------------- #
# 
# Example: Print URI of `at-node-nix' ( unquoted ) for setting an env var.
#
# $ FLAKE_REF="$( nix eval --raw -f inputs.nix at-node-nix; )";
# $ echo "$FLAKE_REF";
# github:aameen-tulip/at-node-nix/ef7cc7ef572f50e537739706668aadb9029d5d1e
# $ nix run "$FLAKE_REF#genMeta" -- --help;
# Generate a Floco metaSet for an NPM registry tarball
# ...
#
#
# ---------------------------------------------------------------------------- #
#
# Example: Print extended attrset of `ak-nix' for use with `builtins.fetchTree'.
#
# $ nix eval --json -f inputs.nix ak-nix.locked|jq;
# {
#   "lastModified": 1670101191,
#   "narHash": "sha256-q9D0cEHvvfTVK+f6hjrEnLtXAiP0cVfrzlOduD/Lz58=",
#   "owner": "aakropotkin",
#   "repo": "ak-nix",
#   "rev": "123fc484c3c68e354704c86a88d88e343e6371f3",
#   "type": "github"
# }
#
#
# ---------------------------------------------------------------------------- #

let

  lib.importJSON = f: builtins.fromJSON ( builtins.readFile f );
  lib.test       = p: s: ( builtins.match p s ) != null;

  # Produce a "locked" URI ref by `type' from its locked attrs.
  # This URI will be interpeted as a "pure" reference by Nix, and is equivalent
  # to the extended set of fields found in the attrset.
  toURIByType = {
    github = { type, owner, repo, rev, ... }: "github:${owner}/${repo}/${rev}";
    file   = { type, url, narHash, ... }: let
      absoluteURI =
        if lib.test ".*:.*" url then "file+" + url else "file:/" + url;
    in absoluteURI + "?narHash=${narHash}";
    tarball = { type, url, narHash, ... }: let
      absoluteURI =
        if lib.test ".*:.*" url then "tarball+" + url else "tarball:/" + url;
    in absoluteURI + "?narHash=${narHash}";
    git = { type, url, rev, ... }: "git+${url}?rev=${rev}";
    path = { type, path, narHash, ... }: "path:${path}?narHash=${narHash}";
    # Technically unreachable for locked nodes, but included for completeness:
    indirect = { type, id, ref ? null, ... }:
      if ref == null then id else "${id}?ref=${ref}";
  };

  # Produce a "locked" URI ref from a node.
  getURI = id: node: let
    inherit (node) locked;
    absoluteURI =
      assert toURIByType ? ${locked.type};
      toURIByType.${locked.type} locked;
    psep = if lib.test ".*\\?.*" absoluteURI then "&" else "?";
  in if locked ? dir then "${absoluteURI}${psep}dir=${locked.dir}" else
     absoluteURI;

  defInput = id: node: let
    self = {
      inherit id;
      inherit (node) locked;
      tree       = builtins.fetchTree node.locked;
      uri        = getURI id node;
      __toString = self: self.uri;
    };
  in self // { flake = builtins.getFlake self.uri; };

  lock = lib.importJSON ./flake.lock;

# ---------------------------------------------------------------------------- #

in builtins.mapAttrs defInput ( removeAttrs lock.nodes ["root"] )


# ---------------------------------------------------------------------------- #
#
# Rime Nix Templates  Copyright (C) 2022  Alex Ameen
#
# This snippet is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#
# ============================================================================ #
