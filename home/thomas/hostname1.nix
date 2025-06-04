{ ... }:
{
  imports = [
    #
    # ========== Required Configs ==========
    #
    common/core

    #
    # ========== Host-specific Optional Configs ==========
    #
    # FIXME(starter): add or remove any optional config directories or files ehre
    common/optional/browsers
    common/optional/desktops
    common/optional/comms
    common/optional/media

    #common/optional/sops.nix
  ];

}
