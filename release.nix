{ pkgs ? import ./nixpkgs {} }:

assert builtins.storeDir == "/nix/store";

let

  inherit (pkgs) nix cacert buildEnv runCommand;

  name = "mini-nix-${nix.version}";

  env = buildEnv {
    name = "mini-nix-env-${nix.version}";
    paths = [ nix cacert ];
  };

  closure = pkgs.closureInfo { rootPaths = [ env ]; };

in
runCommand name {} ''
  dir=${name}
  tarball_name=$dir.tar.gz
  tarball_path=$out/$tarball_name
  reginfo=${closure}/registration

  mkdir $out

  tar -czv -f $tarball_path \
    --owner=0 --group=0 \
    --absolute-names \
    --hard-dereference \
    --transform "s,$reginfo,$dir/reginfo," \
    --transform "s,$NIX_STORE,$dir/store,S" \
    $reginfo $(cat ${closure}/store-paths)

  substitute ${./install.sh.in} $out/install.sh \
    --subst-var-by tarball_name $tarball_name \
    --subst-var-by expected_sha256 "$(sha256sum $tarball_path | cut -c 1-64)" \
    --subst-var-by env_store_path ${env}
''
