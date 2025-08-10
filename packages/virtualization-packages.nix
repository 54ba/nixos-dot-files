{ pkgs, config ? {}, lib ? pkgs.lib }:

with pkgs; 
let
  # Use optionals with lib if available, otherwise provide a fallback
  optionals = if lib ? optionals then lib.optionals else (cond: list: if cond then list else []);
  # Check config for virtualization options, default to false
  virtualboxEnabled = if config ? custom && config.custom ? virtualization && config.custom.virtualization ? virtualbox then config.custom.virtualization.virtualbox.enable else false;
  kvmEnabled = if config ? custom && config.custom ? virtualization && config.custom.virtualization ? kvm then config.custom.virtualization.kvm.enable else false;
  libvirtEnabled = if config ? custom && config.custom ? virtualization && config.custom.virtualization ? libvirt then config.custom.virtualization.libvirt.enable else false;
in
  (optionals virtualboxEnabled [
    virtualbox
  ]) ++
  (optionals kvmEnabled [
    qemu_kvm
    OVMF
    virtiofsd
  ]) ++
  (optionals libvirtEnabled [
    virt-manager
    libvirt
    virt-viewer
    virtiofsd
  ])
