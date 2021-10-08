assert builtins.storeDir == "/nix/store";

let

  mkInstaller = { pkgs, mkTarballUrl }:

    let
      inherit (pkgs) hostPlatform nixUnstable cacert buildEnv runCommand;

    in rec {

      nix = nixUnstable;

      env = buildEnv {
        name = "min-nix-env-${nix.version}";
        paths = [ nix cacert ];
      };

      closure = pkgs.closureInfo { rootPaths = [ env ]; };

      archiveName = "min-nix-${nix.version}-${hostPlatform.system}";

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

      tarballName = "${archiveName}.tar.gz";

      tarballUrl = mkTarballUrl tarballName;

      scriptTemplate = runCommand scriptName {} ''
        substitute ${./install.sh.in} $out \
          --subst-var-by tarball_sha256 "$(sha256sum ${tarball} | cut -d ' ' -f 1)" \
          --subst-var-by archive_name ${archiveName} \
          --subst-var-by env_store_path ${env}
      '';

      scriptName = "install-${hostPlatform.system}.sh";

      script = runCommand scriptName {} ''
        substitute ${scriptTemplate} $out \
          --subst-var-by tarball_url ${tarballUrl}
      '';

      scriptSha256Name = "${scriptName}.sha256.txt";

      scriptSha256 = runCommand scriptSha256Name {} ''
        sha256sum ${script} | cut -d ' ' -f 1 > $out
      '';

    };

in

let

  pkgs = import ./nixpkgs {};

  inherit (pkgs) lib writeText linkFarm;

  platforms = {
    aarch64 = pkgs.pkgsCross.aarch64-multiplatform;
  } // {
    ${pkgs.hostPlatform.parsed.cpu.name} = pkgs;
  };

  mkInstallers = { mkTarballUrl }:
    let
      byPlatform = lib.flip lib.mapAttrs platforms (_: pkgs: mkInstaller { inherit pkgs mkTarballUrl; });

      representativeContent = writeText "representative-content"
        (toString (lib.mapAttrsToList (_: installer: installer.scriptTemplate) byPlatform));

      representativeHash = lib.substring 0 10
        (lib.removePrefix "${builtins.storeDir}/" representativeContent.outPath);

    in {
      inherit byPlatform representativeHash;
      
      links = linkFarm "links" ([
        { name = "VERSION"; path = writeText "VERSION" representativeHash; }
      ] ++ lib.concatLists ((lib.flip lib.mapAttrsToList byPlatform (_: installer: with installer; [
        { name = scriptName; path = script; }
        { name = scriptSha256Name; path = scriptSha256; }
        { name = tarballName; path = tarball; }
      ]))));
    };

  installers = mkInstallers {
    mkTarballUrl = tarballName:
      let
        tag = "dist-${installers.representativeHash}";
      in
        "https://github.com/nspin/minimally-invasive-nix-installer/raw/${tag}/dist/${tarballName}";
  };

in {
  inherit pkgs installers mkInstallers;
}
