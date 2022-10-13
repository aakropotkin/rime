# ============================================================================ #
#
# Git imposes the following rules on how references are named:
#
# - They can include slash '/' for hierarchical (directory) grouping, but no
#   slash-separated component can begin with a dot '.' or end with the sequence
#   sequence ".lock".
# - They must contain at least one '/'.
#   + This enforces the presence of a category like "heads/", "tags/" etc. but
#     the actual names are not restricted.
#   + If the --allow-onelevel option is used, this rule is waived.
# - They cannot have two consecutive dots ".." anywhere.
# - They cannot have ASCII control characters.
#   + i.e. bytes whose values are lower than '\040', or '\177' DEL), space,
#   tilde '~', caret '^', or colon ':' anywhere.
# - They cannot have question-mark '?', asterisk '*', or open bracket
#   '[' anywhere.
#   + See the --refspec-pattern option below for an exception to this rule.
# - They cannot begin or end with a slash '/' or contain multiple
#   consecutive slashes.
#   + see the --normalize option below for an exception to this rule.
# - They cannot end with a dot '.'.
# - They cannot contain a sequence "@{".
# - They cannot be the single character '@'.
# - They cannot contain a '\'.
#
# Source:  https://git-scm.com/docs/git-check-ref-format
#
#
# ---------------------------------------------------------------------------- #

{ ytypes }: let

  yt       = ytypes.Core // ytypes.Prim;
  lib.test = patt: s: ( builtins.match patt s ) != null;

# ---------------------------------------------------------------------------- #

  RE = {
    ref_chars_nc = "[~:^?*\\[:cntrl:][:space:]";
    ref_chars_p1 = "[^/${RE.ref_chars_nc}]";
    ref_chars_n1 = "[^/.${RE.ref_chars_nc}]";  # No slash or dot
    # ref component must match:
    ref_component_p =
      "${RE.ref_chars_n1}((${RE.ref_chars_p1})*${RE.ref_chars_p1})?";
    # ref component must not match:
    ref_component_np = "(.*(@\\{|\\.\\.).*|.*\\.lock|@)";

    # Ref is a series of slash separated components
    ref_p =
      "${RE.ref_component_p}/${RE.ref_component_p}(/${RE.ref_component_p})*";
    ref_np =
      "${RE.ref_component_np}/${RE.ref_component_np}(/${RE.ref_component_np})*";

  };


# ---------------------------------------------------------------------------- #

  Strings = {
    ref_component = let
      cond = s: ( lib.test RE.ref_component_p s ) &&
                ( ! ( lib.test RE.ref_component_np s ) );
    in yt.restrict "git:ref:component" cond yt.string;

    ref_strict = let
      cond = s: ( lib.test RE.ref_p s ) && ( ! ( lib.test RE.ref_np s ) );
    in yt.restrict "git:ref" cond yt.string;
  };


# ---------------------------------------------------------------------------- #

  Eithers.ref = yt.either Strings.ref_strict Strings.ref_component;


# ---------------------------------------------------------------------------- #

  # Non-strict
  tryParseRef = x: let
    sp = builtins.split "/" x;
    st = builtins.filter builtins.isString sp;
    ok = builtins.all Strings.ref_component.check st;
  in if ok then st else null;

  parseRef =
    yt.defun [Eithers.ref ( yt.list Strings.ref_component )] tryParseRef;


# ---------------------------------------------------------------------------- #

in {
  inherit RE Strings Eithers;
  inherit
    tryParseRef
    parseRef
  ;
  # Must include at least two component.
  # This is the "real" requirement.
  isRefStrict = Strings.ref_strict.check;
  # Leading component may be omitted, and is assumed to be `head'.
  isRef = Eithers.ref.check;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
