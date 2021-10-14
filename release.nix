assert builtins.storeDir == "/nix/store";

let
  pkgs = import ./nixpkgs {
    overlays = [
      (self: super: {
        nixUnstable = super.nixUnstable.overrideAttrs (attrs: {
          postPatch = ''
            ${attrs.postPatch or ""}

            substituteInPlace src/libfetchers/git.cc \
              --replace \
                "Activity act(*logger, lvlTalkative, actUnknown, fmt(\"fetching Git repository '%s'\", actualUrl));" \
                "Activity act(*logger, lvlNotice,    actUnknown, fmt(\"fetching Git repository '%s'\", actualUrl));"
          '';
        });
      })
    ];
  };

in
let

  inherit (pkgs) lib writeText linkFarm;

  sha256 = name: path:
    let
      fileName = "${name}.sha256.txt";
    in
      pkgs.runCommand fileName {
        passthru = { inherit fileName; };
      } ''
        sha256sum ${path} | cut -d ' ' -f 1 > $out
      '';

  scriptNamePrefix = "install-min-nix";

  mkScriptName = system: "${scriptNamePrefix}-${system}.sh";

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

      metaScriptName = "${scriptNamePrefix}.sh";

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

      fragmentName = "${scriptNamePrefix}.fragment.sh";

      fragmentTemplate = pkgs.writeText "${fragmentName}.in" ''
        set -e

        script_name="${metaScriptName}"
        script_url="${mkUrl metaScriptName}"
        script_sha256="@script_sha256@"

        curl -fL "$script_url" -o "$script_name"
        echo "$script_sha256 $script_name" | sha256sum -c -
        bash "$script_name"
        rm "$script_name"
      '';

      fragment = pkgs.runCommand fragmentName {} ''
        substitute ${fragmentTemplate} $out \
          --subst-var-by script_sha256 "$(cat ${metaScriptSha256})"
      '';

    in {
      inherit byPlatform representativeHash;
      
      links = linkFarm "links" ([
        { name = "VERSION"; path = writeText "VERSION" representativeHash; }
        { name = fragmentName; path = fragment; }
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
