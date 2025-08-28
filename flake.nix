{
  description = "Chicken shell - a minimal wayland desktop shell built with Quickshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      quickshell,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      packages = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          qs = quickshell.packages.${system}.default.override {
            withX11 = false;
            withI3 = false;
          };

          runtimeDeps = with pkgs; [
            bash
            brightnessctl
            cliphist
            coreutils
            file
            findutils
            gpu-screen-recorder
            libnotify
            matugen
            networkmanager
            wl-clipboard
            systemdMinimal
          ];

          fontconfig = pkgs.makeFontsConf {
            fontDirectories = [
              pkgs.material-symbols
              pkgs.open-sans
              pkgs.inter-nerdfont
            ];
          };
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "chicken-shell";
            version = self.rev or self.dirtyRev or "dirty";
            src = ./.;

            nativeBuildInputs = [
              pkgs.gcc
              pkgs.makeWrapper
              pkgs.qt6.wrapQtAppsHook
            ];
            buildInputs = [
              qs
              pkgs.xkeyboard-config
              pkgs.qt6.qtbase
            ];
            propagatedBuildInputs = runtimeDeps;

            installPhase = ''
              mkdir -p $out/share/chicken-shell
              cp -r ./* $out/share/chicken-shell

              makeWrapper ${qs}/bin/qs $out/bin/chicken-shell \
                --prefix PATH : "${pkgs.lib.makeBinPath runtimeDeps}" \
                --set FONTCONFIG_FILE "${fontconfig}" \
                --add-flags "-p $out/share/chicken-shell"
            '';

            meta = {
              description = "A minimal desktop shell built with Quickshell.";
              homepage = "https://github.com/hannahfluch/chicken-shell";
              license = pkgs.lib.licenses.mit;
              mainProgram = "chicken-shell";
            };
          };
        }
      );

      defaultPackage = eachSystem (system: self.packages.${system}.default);
    };
}
