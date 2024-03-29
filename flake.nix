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
      withDocs ? false,
      withHomeManager ? true,
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
          (lib.optionals withHomeManager [
            home-manager.nixosModules.home-manager
            ({pkgs, ...}:
              with lib; {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
              })
          ])
          [
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
              })
             # other miscellaneous defaults ::
            ({pkgs, ...}:
              with lib; {
                boot.loader.efi.canTouchEfiVariables = mkDefault true;
                boot.loader.grub.configurationLimit = mkDefault 10;
                boot.loader.systemd-boot.enable = mkDefault true;
                documentation.dev.enable = mkDefault withDocs;
                documentation.doc.enable = mkDefault withDocs;
                documentation.info.enable = mkDefault withDocs;
                documentation.man.enable = mkDefault withDocs;
                documentation.man.generateCaches = mkDefault withDocs;
                documentation.man.man-db.enable = mkDefault withDocs;
                documentation.nixos.enable = mkDefault withDocs;
                environment.enableAllTerminfo = mkDefault true;
                hardware.gpgSmartcards.enable = mkDefault true;
                i18n.defaultLocale = mkDefault "en_US.UTF-8";
                networking.hostName = mkDefault hostName;
                nix.gc.automatic = true;
                nix.gc.dates = "daily";
                nix.gc.options = ''--max-freed "$((30 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
                nix.optimise.automatic = mkDefault true;
                nix.readOnlyStore = mkForce true;
                nix.requireSignedBinaryCaches = mkForce true;
                nix.settings.auto-optimise-store = mkDefault true;
                nix.useSandbox = true;
                nixpkgs.config.allowUnfree = mkDefault true;
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
                programs.starship.settings.add_newline = true;
                programs.starship.settings.character.error_symbol = "[➜](bold bright red)";
                programs.starship.settings.character.success_symbol = "[➜](bold bright green)";
                programs.starship.settings.scan_timeout = 10;
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
                system.stateVersion = mkDefault stateVersion;
                system.nixos.tags = ["fnctl"];
                systemd.enableCgroupAccounting = mkDefault true;
                systemd.enableUnifiedCgroupHierarchy = mkDefault true;
                time.hardwareClockInLocalTime = mkDefault true;
                time.timeZone = mkDefault "America/New_York";
                users.allowNoPasswordLogin = mkDefault false;
                users.defaultUserShell = pkgs.zsh;
                users.enforceIdUniqueness = mkDefault true;
                users.groups.users = {};
                users.mutableUsers = mkDefault true;
                users.users.root.initialPassword = mkDefault "b7c1421e-9922-451d-b4d9-ed64b469773b";
              })
          ]
          (lib.optionals (args ? "modules" && lib.isList args.modules) args.modules)
        ];
      };
  };
}
