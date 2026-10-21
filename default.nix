# PHP security-bump overlay, used by Nixpacks/Coolify via `nixOverlays`.
#
# For each branch: put the new version and the SHA-256 that php.net
# publishes for the .tar.bz2 on https://www.php.net/downloads (hex is fine,
# fetchurl accepts it as-is). No fake-hash round trip needed.
final: prev:

let
  inherit (final) lib;

  targets = {
    php85 = {
      version = "8.5.12";
      sha256 = "ffb60edc437ced63b5137e4984db379a8111c50049c711510d8b958277efc1a8";
    };
    php84 = {
      version = "8.4.27";
      sha256 = "b2530a877c722f4b08c9e174a30cb08bac2b7e1903ee6e9e315f0aa9f5f82c24";
    };
    php83 = {
      version = "8.3.36";
      sha256 = "46f4b45e3688ed2b1819015a7b532c15b51cc055bdd3b13fd00ddfeebeedcd5f";
    };
  };

  bump =
    name:
    { version, sha256 }:
    let
      orig =
        prev.${name}
          or (throw "php overlay: ${name} does not exist in this nixpkgs revision; cannot bump to ${version}");
    in
    # Never downgrade: once nixpkgs has caught up (or passed) this version,
    # the overlay becomes a no-op and prints a reminder to remove it.
    if lib.versionOlder orig.version version then
      orig.overrideAttrs (old: {
        inherit version;
        src = final.fetchurl {
          url = "https://www.php.net/distributions/php-${version}.tar.bz2";
          inherit sha256;
        };
      })
    else
      lib.warn "php overlay: nixpkgs ${name} is already ${orig.version} (>= ${version}); remove this override" orig;
in
# Fails evaluation (and therefore the build) if a listed branch is missing.
builtins.mapAttrs bump targets
