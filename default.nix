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
      version = "8.5.13";
      sha256 = "47d50c36016784a4a71f019cd7bfa29c31e4be0de22d3fa06095b280a6299e2f";
    };
    php84 = {
      version = "8.4.28";
      sha256 = "b23aa1be5b74629ad624fd01365c0e4df6d8878473983f337349433ef349c1f7";
    };
    php83 = {
      version = "8.3.37";
      sha256 = "7837b43cd4e18db5deac21ee6f00866e4779a705f2e54faea83c8a6cf56fd1d8";
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
      (orig.override {
        # Applies to the extension set built for this PHP. Kept through the
        # overrideAttrs below, which rebuilds PHP with the same arguments.
        packageOverrides = pfinal: pprev: {
          extensions = pprev.extensions // {
            filter = pprev.extensions.filter.overrideAttrs (old: {
              # These memory-limit tests fail inside the Coolify build
              # container; drop just these three, keep the rest of the suite.
              preCheck = (old.preCheck or "") + ''
                find . \( -name oom_filter_default_encoded.phpt \
                  -o -name oom_filter_input.phpt \
                  -o -name oom_filter_input_array.phpt \) -delete
              '';
            });
          };
        };
      }).overrideAttrs
        (old: {
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
