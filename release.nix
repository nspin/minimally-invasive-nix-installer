assert builtins.storeDir == "/nix/store";

let

  sha256 = name: path:
    let
      fileName = "${name}.sha256.txt";
    in
      pkgs.runCommand fileName {
        passthru = { inherit fileName; };
      } ''
        sha256sum ${path} | cut -d ' ' -f 1 > $out
      '';

  mkScriptName = system: "install-min-nix-${system}.sh";

  mkInstaller = { thesePkgs, mkUrl }:

    let
      inherit (thesePkgs) hostPlatform nixUnstable cacert buildEnv runCommand;

    in rec {

      nix = nixUnstable;

      env = buildEnv {
        name = "min-nix-env-${nix.version}";
        paths = [ nix cacert ];
      };

      closure = thesePkgs.closureInfo { rootPaths = [ env ]; };

      archiveName = "min-nix-${nix.version}-${hostPlatform.system}";

      tarballName = "${archiveName}.tar.gz";

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

      tarballSha256 = sha256 tarballName tarball;

      tarballUrl = mkUrl tarballName;

      scriptTemplate = runCommand scriptName {} ''
        substitute ${./install-system.sh.in} $out \
          --subst-var-by tarball_sha256 "$(cat ${tarballSha256})" \
          --subst-var-by archive_name ${archiveName} \
          --subst-var-by env_store_path ${env}
      '';

      scriptName = mkScriptName hostPlatform.system;

      script = runCommand scriptName {} ''
        substitute ${scriptTemplate} $out \
          --subst-var-by tarball_url ${tarballUrl}
      '';

      scriptSha256 = sha256 scriptName script;

    };

  pkgs = import ./nixpkgs {};

  inherit (pkgs) lib writeText linkFarm;

  platforms = {
    aarch64 = pkgs.pkgsCross.aarch64-multiplatform;
  } // {
    ${pkgs.hostPlatform.parsed.cpu.name} = pkgs;
  };

  mkInstallers = { mkUrl }:
    let
      byPlatform = lib.flip lib.mapAttrs platforms (_: thesePkgs: mkInstaller { inherit thesePkgs mkUrl; });

      representativeContent = writeText "representative-content"
        (toString ((lib.mapAttrsToList (_: installer: installer.scriptTemplate) byPlatform) ++ [
          ./install.sh.in
        ]));

      representativeHash = lib.substring 0 10
        (lib.removePrefix "${builtins.storeDir}/" representativeContent.outPath);

      metaScriptName = "install-min-nix.sh";

      scriptNameExpression = mkScriptName "\${arch}-linux";
      scriptUrlExpression = mkUrl scriptNameExpression;

      caseArms =
        let
          indent = "    ";
        in
          lib.concatStringsSep indent (lib.flip lib.mapAttrsToList byPlatform (arch: installer: ''
            ${arch}) script_sha256=$(cat ${installer.scriptSha256}) ;;
          ''));

      metaScript = pkgs.runCommand metaScriptName {} ''
        substitute ${./install.sh.in} $out \
          --subst-var-by script_name_expression '${scriptNameExpression}' \
          --subst-var-by script_url_expression '${scriptUrlExpression}' \
          --subst-var-by case_arms "${caseArms}"
      '';

      metaScriptSha256 = sha256 metaScriptName metaScript;

    in {
      inherit byPlatform representativeHash;
      
      links = linkFarm "links" ([
        { name = "VERSION"; path = writeText "VERSION" representativeHash; }
        { name = metaScriptName; path = metaScript; }
        { name = metaScriptSha256.fileName; path = metaScriptSha256; }
      ] ++ lib.concatLists (lib.flip lib.mapAttrsToList byPlatform (_: installer: with installer; [
        { name = scriptName; path = script; }
        { name = scriptSha256.fileName; path = scriptSha256; }
        { name = tarballName; path = tarball; }
        { name = tarballSha256.fileName; path = tarballSha256; }
      ])));
    };

  installers = mkInstallers {
    mkUrl = fileName:
      let
        tag = "dist-${installers.representativeHash}";
      in
        "https://github.com/nspin/minimally-invasive-nix-installer/raw/${tag}/dist/${fileName}";
  };

in {
  inherit pkgs installers mkInstallers;
}
