# User config applicable only to nixos
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hostSpec = config.hostSpec;
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;

  # Decrypt password to /run/secrets-for-users/ so it can be used to create the user
  #sopsHashedPasswordFile = lib.optionalString (
  #  !config.hostSpec.isMinimal
  #) config.sops.secrets."passwords/${hostSpec.username}".path;
in
{
  users.mutableUsers = false; # Only allow declarative credentials; Required for password to be set via sops during system activation!
  users.users.${hostSpec.username} = {
    home = "/home/${hostSpec.username}";
    isNormalUser = true;
    hashedPassword = "$6$MDqjXI2k6nhJDz2c$CmIca2f7Ozr1hdeTCK9o5x0.vnL3k8Af7ynm6ajWy4KNArjbfVMumcL3FkBjYUpBcWuKVIHCOGREGe5IOET9D0";
    #hashedPasswordFile = sopsHashedPasswordFile; # Blank if sops is not working.

    extraGroups = lib.flatten [
      "wheel"
      (ifTheyExist [
        "audio"
        "video"
        "docker"
        "git"
        "networkmanager"
        "scanner" # for print/scan"
        "lp" # for print/scan"
      ])
    ];
  };

  # No matter what environment we are in we want these tools for root, and the user(s)
  programs.git.enable = true;

  # root's ssh key are mainly used for remote deployment, borg, and some other specific ops
  users.users.root = {
    shell = pkgs.bash;
    #hashedPasswordFile = config.users.users.${hostSpec.username}.hashedPasswordFile;
    hashedPassword = "$6$MDqjXI2k6nhJDz2c$CmIca2f7Ozr1hdeTCK9o5x0.vnL3k8Af7ynm6ajWy4KNArjbfVMumcL3FkBjYUpBcWuKVIHCOGREGe5IOET9D0";
    #hashedPassword = config.users.users.${hostSpec.username}.hashedPassword; # This comes from hosts/common/optional/minimal.nix and gets overridden if sops is working
    openssh.authorizedKeys.keys = config.users.users.${hostSpec.username}.openssh.authorizedKeys.keys; # root's ssh keys are mainly used for remote deployment.
  };
}

