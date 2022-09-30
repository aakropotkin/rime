# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  inherit (lib.libyants)
    any attrs bool defun drv either eitherN enum float function int list option
    path restrict string struct sum type unit
  ;

  # # Test that structures work as planned.
  # person = struct "person" {
  #   name = string;
  #   age = int;
  #   contact = option (struct {
  #     email = string;
  #     phone = option string;
  #   });
  # };
  #
  #
  # # Test enum definitions & matching
  # colour = enum "colour" [ "red" "blue" "green" ];
  # colourMatcher = {
  #   red = "It is in fact red!";
  #   blue = "It should not be blue!";
  #   green = "It should not be green!";
  # };
  #
  #
  # # Test sum type definitions
  # creature = sum "creature" {
  #   human = struct {
  #     name = string;
  #     age = option int;
  #   };
  #   pet = enum "pet" [ "dog" "lizard" "cat" ];
  # };
  # some-human = creature {
  #   human = {
  #     name = "Brynhjulf";
  #     age = 42;
  #   };
  # };

# ---------------------------------------------------------------------------- #

  fr-id = let
    cond = lib.test "[a-zA-Z][a-zA-Z0-9_-]*";
  in restict "flake-ref:id" cond string;

  git-owner = let
    chars = lib.test "[a-zA-Z0-9]([a-zA-Z0-9-]*[^-])?";
    # No consecutive hyphens are allowed
    hyphens = s: ! ( lib.test ".*--.*" s );
    len = s: ( builtins.stringLength s ) <= 39;
    cond = s: ( len s ) && ( chars s ) && ( hyphens s );
  in restrict "git:owner" cond string;


# ---------------------------------------------------------------------------- #

  flake-ref = struct "flake-ref" {
    type         = enum ["path" "tarball" "file" "git" "indirect"];
    id           = option fr-id;
    ref          = option string;
    url          = option string;
    path         = option string;  # Again, not really a path.
    owner        = option git-owner;
    repo         = option string;
    rev          = option string;
    dir          = option string;  # Not actually a path.
    narHash      = option string;
    lastModified = option int;
  };



# ---------------------------------------------------------------------------- #

in {
  inherit
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
