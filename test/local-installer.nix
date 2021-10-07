let
  pkgs = import ../nixpkgs {};
  release = import ../release.nix;

  installers = release.mkInstallers {
    mkTarballUrl = tarballName: "http://localhost:8000/${tarballName}";
  };

in {

  testBundle = pkgs.runCommand "test-bundle" {} ''
    cp -rL ${installers.links} $out
  '';

}
