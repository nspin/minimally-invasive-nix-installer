{ pkgs ? import ./nixpkgs {} }:

assert builtins.storeDir == "/nix/store";

let

  inherit (pkgs) lib nixUnstable cacert buildEnv runCommand writeText linkFarm;

  nix = nixUnstable;

  env = buildEnv {
    name = "min-nix-env-${nix.version}";
    paths = [ nix cacert ];
  };

  closure = pkgs.closureInfo { rootPaths = [ env ]; };

  archiveName = "min-nix-${nix.version}";

  tarball = runCommand tarballName {} ''
    dir=${archiveName}
    reginfo=${closure}/registration

    tar -czv -f $out \
      --owner=0 --group=0 \
      --sort=name \
      --absolute-names \
      --hard-dereference \
      --transform "s,$reginfo,$dir/reginfo," \
      --transform "s,$NIX_STORE,$dir/store,S" \
      $reginfo $(cat ${closure}/store-paths)
  '';

  scriptTemplate = runCommand scriptName {} ''
    substitute ${./install.sh.in} $out \
      --subst-var-by tarball_sha256 "$(sha256sum ${tarball} | cut -d ' ' -f 1)" \
      --subst-var-by archive_name ${archiveName} \
      --subst-var-by env_store_path ${env}
  '';

  mkScript = { tarballUrl }: runCommand scriptName {} ''
    substitute ${scriptTemplate} $out \
      --subst-var-by tarball_url ${tarballUrl}
  '';

  scriptName = "install.sh";
  tarballName = "${archiveName}.tar.gz";

  tag = "dist-${lib.substring 0 10 (lib.removePrefix "${builtins.storeDir}/" scriptTemplate.outPath)}";
  tarballUrl = "https://raw.githubusercontent.com/nspin/minimally-invasive-nix-installer/${tag}/${tarballName}";

  script = mkScript {
    inherit tarballUrl;
  };

  links = linkFarm "links" [
    { name = tarballName; path = tarball; }
    { name = scriptName; path = script; }
    { name = "TAG"; path = writeText "TAG" tag; }
  ];

in rec {

  inherit nix env tarball script links;

}
