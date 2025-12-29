{
  description = "flakification of ksysguard6";

  inputs = {
    nixpkgs = {
      url = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs }:
    let systems = ["x86_64-linux" "i686-linux" "aarch64-linux"];
        lib = nixpkgs.lib;
        forEachSystem = lib.genAttrs systems;

        mkKsysguard6 = pkgs:
          pkgs.stdenv.mkDerivation {
            pname = "ksysguard";
            version = "6.0.1";

            src = ./.;

            buildInputs = [
              pkgs.qt6.qtbase

              pkgs.kdePackages.libksysguard

              pkgs.lm_sensors

              pkgs.libnl
            ];

            # takes care of placing the .desktop under $out/share/applications/hello.desktop
            nativeBuildInputs = [
              pkgs.extra-cmake-modules
              pkgs.kdePackages.kdoctools
              pkgs.qt6.wrapQtAppsHook
            ] ++
            (pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.copyDesktopItems ]);

            cmakeFlags = [
              "BUILD_TESTING=OFF"
              "WITH_SYSTEMMONITOR=OFF"
              # Debug build
              # "CMAKE_VERBOSE_MAKEFILE=ON"
              # "VERBOSE=ON"
            ];

            # Zero out PATH so that ksysguard will be unable to find ‘nvidia-smi’ executable.
            qtWrapperArgs = [ ''--set PATH ""'' ];

            # How general mkDerivation looks like
            # buildPhase = ''
            #   ./configure
            #   make
            # '';
            #
            # installPhase = ''
            #   mkdir -p $out/bin
            #   cp hello $out/bin
            # '';
            #
            # postInstall =
            #   with pkgs;
            #   lib.optionalString stdenv.isLinux ''
            #     # install icon
            #     mkdir -p "$out/share/icons/hicolor/scalable/apps"
            #     install -Dm644 icons/logo.svg $out/share/icons/hicolor/scalable/apps/org.reciperium.hello.svg
            #   '';
          };
    in {
      packages = forEachSystem (system: {
        ksysguard6 =
          let pkgs = import nixpkgs {
                inherit system;
                overlays = [ self.overlays.default ];
              };
          in pkgs.sergv-extensions.ksysguard6;
        # let ps = nixpkgs.legacyPackages.${system};
        #     pkgs = self.overlays.fix-libksysguard pkgs ps;
        # in pkgs.ksysguard6;
      });

      overlays.default = final: prev: {
        sergv-extensions = {
          ksysguard6 = mkKsysguard6 final;
        };

        kdePackages = prev.kdePackages // {

          libksysguard = prev.kdePackages.libksysguard.overrideAttrs (old: {
            patches = (old.patches or []) ++ [
              ./0001-Export-header-still-used-by-ksysguard.patch
              ./0002-Disable-GPU-and-network-plugins.patch
            ];
          });

        };

      };
    };
}

# mkDerivation {
#   pname = "plasma-systemmonitor";
#   nativeBuildInputs = [
#     extra-cmake-modules
#     kdoctools
#   ];
#   buildInputs = [
#     qtquickcontrols2
#     kconfig
#     kcoreaddons
#     ki18n
#     kitemmodels
#     kitemviews
#     knewstuff
#     kiconthemes
#     libksysguard
#     kquickcharts
#     ksystemstats
#     qqc2-desktop-style
#   ];
# }

