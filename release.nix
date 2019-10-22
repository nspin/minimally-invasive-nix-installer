{ pkgs ? import ./nixpkgs {} }:

assert builtins.storeDir == "/nix/store";

let

  inherit (pkgs) nix cacert buildEnv runCommand;

  archive_name = "mini-nix-${nix.version}";
  tarball_name = "${archive_name}.tar.gz";
  script_name = "install.sh";

  env = buildEnv {
    name = "mini-nix-env-${nix.version}";
    paths = [ nix cacert ];
  };

  closure = pkgs.closureInfo { rootPaths = [ env ]; };

  tarball_url = "http://localhost:8000/${tarball_name}";

in rec {

  tarball = runCommand tarball_name {} ''
    dir=${archive_name}
    reginfo=${closure}/registration

    tar -czv -f $out \
      --owner=0 --group=0 \
      --absolute-names \
      --hard-dereference \
      --transform "s,$reginfo,$dir/reginfo," \
      --transform "s,$NIX_STORE,$dir/store,S" \
      $reginfo $(cat ${closure}/store-paths)
  '';

  mk_script = { tarball_url }: runCommand script_name {} ''
    substitute ${./install.sh.in} $out \
      --subst-var-by tarball_url ${tarball_url} \
      --subst-var-by tarball_sha256 "$(sha256sum ${tarball} | cut -c 1-64)" \
      --subst-var-by archive_name ${archive_name} \
      --subst-var-by env_store_path ${env}
  '';

  script = mk_script {
    inherit tarball_url;
  };

  bundle = runCommand "bundle" {} ''
    mkdir $out
    cp ${tarball} $out/${tarball_name}
    cp ${script} $out/${script_name}
  '';

}
