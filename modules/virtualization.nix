{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.virtualization = {
      enable = mkEnableOption "virtualization services";
      virtualbox.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable VirtualBox virtualization";
      };
      kvm.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable KVM/QEMU virtualization";
      };
      libvirt.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable libvirt virtualization management";
      };
    };
  };

  config = mkIf config.custom.virtualization.enable {
    # VirtualBox configuration and permissions
    virtualisation.virtualbox.host = mkIf config.custom.virtualization.virtualbox.enable {
      enable = true;
      enableExtensionPack = false;
      addNetworkInterface = true;
    };

    # KVM/QEMU virtualization
    virtualisation.libvirtd = mkIf config.custom.virtualization.kvm.enable {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMF.fd ];
        };
      };
    };

    # Enable libvirt management
    programs.virt-manager.enable = mkIf config.custom.virtualization.libvirt.enable true;

    # Add virtualization packages
    environment.systemPackages = import ../packages/virtualization-packages.nix { inherit pkgs config lib; };

    # Ensure user groups exist and are configured
    users.groups = mkIf config.custom.virtualization.enable {
      vboxusers = mkIf config.custom.virtualization.virtualbox.enable {};
      libvirtd = mkIf config.custom.virtualization.kvm.enable {};
      kvm = mkIf config.custom.virtualization.kvm.enable {};
    };

    # Add systemd tmpfiles rules for VirtualBox
    systemd.tmpfiles.rules = mkIf config.custom.virtualization.virtualbox.enable [
      # VirtualBox directories - fix path with space
      "d '/home/mahmoud/VirtualBox VMs' 0755 mahmoud users -"
    ];
  };
}
