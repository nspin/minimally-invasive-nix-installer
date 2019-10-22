let
  pkgs = import ../nixpkgs {};
  release = import ../release.nix {};

  tarball_name = "x.tar.gz";
  tarball_url = "http://localhost:8000/${tarball_name}";

  script_name = "install.sh";
  script = release.mk_script {
    inherit tarball_url;
  };

in {

  test_bundle = pkgs.runCommand "test_bundle" {} ''
    mkdir $out
    cp ${release.tarball} $out/${tarball_name}
    cp ${script} $out/${script_name}
  '';

}
