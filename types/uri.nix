# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt    = lib.libyants;
  pats  = lib.regexps.uri.patterns;
  tpat' = name: pname: yt.restrict name ( lib.test pats.${pname} ) yt.string;
  tpat  = name: tpat' name "${name}_p";

# ---------------------------------------------------------------------------- #

  Uri = rec {
    Strings = rec {
      rev = tpat' "rev" "git_rev_p";
      # A git ref, such as "git:<OWNER>/<REPO>/release-v1"
      ref = let
        cond = s: ( lib.test pats.maybe_git_ref_p s ) &&
                  ( ! ( lib.test pats.bad_git_ref_p s ) );
      in yt.restrict "ref" cond yt.string;
      # Scheme sub-parts as `<DATA_FORMAT>+<TRANSPORT_LAYER>', e.g. `file+https'
      # This technically isn't standardized but everyone uses it.
      layer         = tpat "layer";
      transport     = layer;
      data          = layer;
      scheme        = tpat "scheme";
      rel_path      = tpat "rel_path";
      abs_path      = tpat "abs_path";
      net_path      = tpat "net_path";
      path          = yt.either abs_path net_path;  # XXX: NOT relative!
      authority     = tpat "authority";
      query         = tpat "query";
      fragment      = tpat "fragment";
      abs_uri       = tpat "abs_uri";
      rel_uri       = tpat "rel_uri";
      uri_ref       = tpat "uri_ref";
      hier_part     = tpat "hier_part";
      opaque_part   = tpat "opaque_part";
      segment       = tpat "segment";
      path_segments = tpat "path_segments";
      userinfo      = tpat "userinfo";
      hostport      = tpat "hostport";
      host          = tpat "host";
      hostname      = tpat "hostname";
      port          = tpat "port";
    };
    Sums = {
      uri = yt.sum "uri" {
        # FIXME: use eithers.
        absolute = Strings.abs_uri;
        relative = Strings.rel_uri;
      };
    };
    Structs = {
      scheme = yt.struct "scheme" {
        transport = Strings.layer;
        data      = yt.option Strings.layer;
      };
      url = yt.struct "url" {
        inherit (Structs) scheme;
        inherit (Strings) path;
        absolute  = yt.bool;
        authority = yt.option ( tpat "authority" );
        query     = yt.option ( tpat "query" );
        fragment  = yt.option ( tpat "fragment" );
      };
    };
  };


# ---------------------------------------------------------------------------- #

in {
  inherit Uri;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
