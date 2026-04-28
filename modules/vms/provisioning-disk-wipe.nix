{
  disko.devices = {
    disk.disk1.content.partitions = {
      esp.content.preCreateHook = ''
        wipefs --all --force "$device" || true
      '';

      root.content.preCreateHook = ''
        vgchange -an pool || true
        wipefs --all --force "$device" || true
      '';
    };

    lvm_vg.pool.lvs.root.content.preCreateHook = ''
      wipefs --all --force "$device" || true
    '';
  };
}
