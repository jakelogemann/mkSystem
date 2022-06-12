{
  description = "fnctl/mkSystem";

  inputs = {
    fnctl-lib.url = "github:fnctl/lib";
    nixpkgs.url = "nixpkgs/nixos-22.05";
    nix.url = "github:nixos/nix/2.9.0";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, ...}: {
    formatter = self.inputs.fnctl-lib.formatter;
    # mkSystem builds a nixosSystem which is pre-configured to have the features we
    # expect.
    mkSystem = {
      system ?
        if builtins ? "currentSystem"
        then builtins.currentSystem
        else "aarch64-linux",
      nixpkgs ? self.inputs.fnctl-lib.inputs.nixpkgs,
      home-manager ? self.inputs.home-manager,
      lib ? self.inputs.fnctl-lib.lib,
      modules ? [],
      stateVersion ? "22.05",
      hostName ? "fnctl",
      userName ? "developer",
      extraArgs ? {},
      ...
    } @ args:
      lib.nixosSystem {
        inherit system;
        # specialArgs is for extra args (in addition to
        # config/options/pkgs/lib/etc.) that should be passed to the
        # nixosModules.
        specialArgs = extraArgs;
        # modules is the list of nixosModules that should be merged (in order).
        modules = lib.concatLists [
          [
            home-manager.nixosModules.home-manager
            ({pkgs, ...}:
              with lib; {
                # use modern nix version and experimental-features
                nix.package = mkForce self.inputs.nix.packages.${pkgs.system}.nix;
                nix.extraOptions = mkDefault ''experimental-features = nix-command flakes '';
                # add all inputs as cached registry entries for cached evaluations
                # and quick `nix search`, etc
                nix.registry = mapAttrs (_: flake: {inherit flake;}) self.inputs;
                # set the `NIX_PATH` so legacy nix commands use the same nixpkgs as
                # the new commands.
                nix.nixPath = mapAttrsToList (name: flake: "${name}=${flake}") self.inputs;
                # seems like lots of things arent _really_ free :(
                nixpkgs.config.allowUnfree = mkDefault true;
                # set the system.stateVersion if it isn't set.
                system.stateVersion = mkDefault stateVersion;
                # set the hostname if it isn't set.
                networking.hostName = mkDefault hostName;
                nix.gc.automatic = true;
                nix.gc.dates = "daily";
                nix.gc.options = ''--max-freed "$((30 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

                # other miscellaneous defaults ::
                boot.loader.efi.canTouchEfiVariables = mkDefault true;
                boot.loader.systemd-boot.enable = mkDefault true;
                documentation.dev.enable = mkDefault false;
                documentation.doc.enable = mkDefault false;
                documentation.info.enable = mkDefault false;
                documentation.man.enable = mkDefault false;
                documentation.man.generateCaches = mkDefault false;
                documentation.man.man-db.enable = mkDefault false;
                documentation.nixos.enable = mkDefault false;
                environment.enableAllTerminfo = mkDefault true;
                hardware.gpgSmartcards.enable = mkDefault true;
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                i18n.defaultLocale = mkDefault "en_US.UTF-8";
                nix.readOnlyStore = mkForce true;
                nix.requireSignedBinaryCaches = mkForce true;
                nix.settings.auto-optimise-store = mkDefault true;
                nix.useChroot = true;
                nix.useSandbox = true;
                programs.git.enable = mkDefault true;
                programs.git.lfs.enable = mkDefault true;
                programs.htop.enable = mkDefault true;
                programs.neovim.defaultEditor = mkDefault true;
                programs.neovim.enable = mkDefault true;
                programs.neovim.viAlias = mkDefault true;
                programs.neovim.vimAlias = mkDefault true;
                programs.neovim.withNodeJs = mkDefault true;
                programs.neovim.withPython3 = mkDefault true;
                programs.neovim.withRuby = mkDefault true;
                programs.starship.enable = true;
                programs.zsh.autosuggestions.enable = mkDefault true;
                programs.zsh.enable = mkDefault true;
                programs.zsh.enableCompletion = mkDefault true;
                programs.zsh.enableGlobalCompInit = mkDefault true;
                programs.zsh.histSize = mkDefault 10000;
                programs.zsh.syntaxHighlighting.enable = mkDefault true;
                security.allowSimultaneousMultithreading = mkDefault false;
                security.allowUserNamespaces = mkDefault true;
                security.forcePageTableIsolation = mkDefault true;
                security.lockKernelModules = mkDefault true;
                security.protectKernelImage = mkDefault true;
                security.rtkit.enable = mkDefault true;
                security.virtualisation.flushL1DataCache = mkDefault "always";
                services.avahi.enable = mkForce false;
                services.fwupd.enable = mkDefault true;
                services.gnome.tracker-miners.enable = mkForce false;
                services.gnome.tracker.enable = mkForce false;
                services.openssh.enable = mkDefault false;
                services.openssh.passwordAuthentication = mkForce false;
                services.pcscd.enable = true;
                services.printing.enable = mkForce false;
                sound.enable = mkDefault true;
                sound.mediaKeys.enable = mkDefault true;
                system.copySystemConfiguration = mkDefault false;
                system.nixos.tags = ["fnctl"];
                systemd.enableCgroupAccounting = mkDefault true;
                systemd.enableUnifiedCgroupHierarchy = mkDefault true;
                time.hardwareClockInLocalTime = mkDefault true;
                time.timeZone = mkDefault "America/New_York";
                users.allowNoPasswordLogin = mkDefault false;
                users.defaultUserShell = pkgs.zsh;
                users.enforceIdUniqueness = mkDefault true;
                users.mutableUsers = mkDefault true;
                users.users.root.initialPassword = mkDefault "b7c1421e-9922-451d-b4d9-ed64b469773b";
                users.users.root.useDefaultUserShell = mkDefault true;
              })
          ]
          (lib.optionals (args ? "modules" && lib.isList args.modules) args.modules)
        ];
      };
  };
}
