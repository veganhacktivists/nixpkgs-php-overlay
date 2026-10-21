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
      version = "8.5.11";
      sha256 = "dc940716a8c73e531c0078eecb955d595d321ec2cc9d47149cf0089ea6e18f64";
    };
    php84 = {
      version = "8.4.26";
      sha256 = "4209694d7b0f63c45a3773e07cdc2bbfc71249265a5d951b1ff53e1147edc5ca";
    };
    php83 = {
      version = "8.3.35";
      sha256 = "e279d9ec90d9bcab900d146816e5b11d3e8924b80e2ba36c7d7dae7d71dcbf2d";
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
