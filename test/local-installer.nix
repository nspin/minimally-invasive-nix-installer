let
  pkgs = import ../nixpkgs {};
  release = import ../release.nix;

  installers = release.mkInstallers {
    mkUrl = fileName: "http://localhost:8000/${fileName}";
  };

in {

  testBundle = pkgs.runCommand "test-bundle" {} ''
    cp -rL ${installers.links} $out
  '';

}
