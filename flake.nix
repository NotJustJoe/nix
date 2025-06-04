{
  description = "EmergentMind's Nix-Config Starter";
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      #
      # ========= Architectures =========
      #
      # NOTE(starter): Comment or uncomment architectures below as required by your hosts.
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      #
      # ========= Host Config Functions =========
      #
      # Handle a given host config based on whether its underlying system is nixos or darwin
      mkHost = host: isDarwin: {
        ${host} =
          let
            func = if isDarwin then inputs.nix-darwin.lib.darwinSystem else lib.nixosSystem;
            systemFunc = func;
          in
          systemFunc {
            specialArgs = {
              inherit
                inputs
                outputs
                isDarwin
                ;

              # ========== Extend lib with lib.custom ==========
              # This approach allows lib.custom to propagate into hm
              # see: https://github.com/nix-community/home-manager/pull/3454
              lib = nixpkgs.lib.extend (self: super: { custom = import ./lib { inherit (nixpkgs) lib; }; });

            };
            modules = [ ./hosts/${if isDarwin then "darwin" else "nixos"}/${host} ];
          };
      };
      # Invoke mkHost for each host config that is declared for either nixos or darwin
      mkHostConfigs =
        hosts: isDarwin: lib.foldl (acc: set: acc // set) { } (lib.map (host: mkHost host isDarwin) hosts);
      # Return the hosts declared in the given directory
      readHosts = folder: lib.attrNames (builtins.readDir ./hosts/${folder});
    in
    {
      #
      # ========= Overlays =========
      #
      # Custom modifications/overrides to upstream packages.
      overlays = import ./overlays { inherit inputs; };

      #
      # ========= Host Configurations =========
      #
      # Building configurations is available through `just rebuild` or `nixos-rebuild --flake .#hostname`
      # NOTE(starter): Only uncomment darwinConfigurations if you actually have a host module configured in `./hosts/darwin`
      nixosConfigurations = mkHostConfigs (readHosts "nixos") false;
      #darwinConfigurations = mkHostConfigs (readHosts "darwin") true;

      #
      # ========= Packages =========
      #
      # Add custom packages to be shared or upstreamed.
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        lib.packagesFromDirectoryRecursive {
          callPackage = lib.callPackageWith pkgs;
          directory = ./pkgs/common;
        }
      );

      #
      # ========= Formatting =========
      #
      # Nix formatter available through 'nix fmt' https://nix-community.github.io/nixpkgs-fmt
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      # Pre-commit checks
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./checks.nix { inherit inputs system pkgs; }
      );

      #
      # ========= DevShell =========
      #
      # Custom shell for bootstrapping on new hosts, modifying nix-config, and secrets management
      devShells = forAllSystems (
        system:
        import ./shell.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          checks = self.checks.${system};
        }
      );
    };

  inputs = {
    #
    # ========= Official NixOS, Nix-Darwin, and HM Package Sources =========
    #
    # NOTE(starter): As with typical flake-based configs, you'll need to update the nixOS, hm,
    # and darwin version numbers below when new releases are available.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # The next two inputs are for pinning nixpkgs to stable vs unstable regardless of what the above is set to.
    # This is particularly useful when an upcoming stable release is in beta because you can effectively
    # keep 'nixpkgs-stable' set to stable for critical packages while setting 'nixpkgs' to the beta branch to
    # get a jump start on deprecation changes.
    # See also 'stable-packages' and 'unstable-packages' overlays at 'overlays/default.nix"
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    #
    # ========= Utilities =========
    #
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Secrets management. See ./docs/secretsmgmt.md
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pre-commit
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
 
    #
    # ========= Personal Repositories =========
    #
    # Private secrets repo.  See ./docs/secretsmgmt.md
    # Authenticates via ssh and use shallow clone
    # FIXME(starter): The url below points to the 'simple' branch of the public, nix-secrets-reference repository which is inherently INSECURE!
    # Replace the url with your personal, private nix-secrets repo.
    #nix-secrets = {
    #  url = "git+ssh://git@github.com/emergentmind/nix-secrets-reference.git?ref=simple&shallow=1";
    #  inputs = { };
    #};
  };
}
