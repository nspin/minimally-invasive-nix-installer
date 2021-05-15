{ pkgs ? import ./nixpkgs {} }:

assert builtins.storeDir == "/nix/store";

let

  inherit (pkgs) nix cacert buildEnv runCommand linkFarm;

  env = buildEnv {
    name = "min-nix-env-${nix.version}";
    paths = [ nix cacert ];
  };

  closure = pkgs.closureInfo { rootPaths = [ env ]; };

  archiveName = "min-nix-${nix.version}";
  tarballName = "${archiveName}.tar.gz";
  scriptName = "install.sh";

  tarballUrl = "https://raw.githubusercontent.com/nspin/minimally-invasive-nix-installer/dist/${tarballName}";

in rec {

  tarball = runCommand tarballName {} ''
    dir=${archiveName}
    reginfo=${closure}/registration

    tar -czv -f $out \
      --owner=0 --group=0 \
      --absolute-names \
      --hard-dereference \
      --transform "s,$reginfo,$dir/reginfo," \
      --transform "s,$NIX_STORE,$dir/store,S" \
      $reginfo $(cat ${closure}/store-paths)
  '';

  mkScript = { tarballUrl }: runCommand scriptName {} ''
    substitute ${./install.sh.in} $out \
      --subst-var-by tarball_url ${tarballUrl} \
      --subst-var-by tarball_sha256 "$(sha256sum ${tarball} | cut -d ' ' -f 1)" \
      --subst-var-by archive_name ${archiveName} \
      --subst-var-by env_store_path ${env}
  '';

  script = mkScript {
    inherit tarballUrl;
  };

  links = linkFarm "links" [
    { name = tarballName; path = tarball; }
    { name = scriptName; path = script; }
  ];

}
