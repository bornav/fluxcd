{
  boot.kernelModules = [ "dm_thin_pool" ];
  disko.devices = {
    disk.disk1.content.partitions = {
      lvm = {
        size = "100%";
        content = {
          type = "lvm_pv";
          vg = "lvmvg";
        };
      };
    };
    lvm_vg = {
      lvmvg = {
        type = "lvm_vg";
        lvs = {};
      };
    };

    # for clean lvm drive that can be selfmanaged by miroir
    # disk.disk1.content.partitions = {
    #   lvm = {
    #     size = "100%";
    #     content = {
    #       type = "lvm_pv";
    #       vg = "mainpool";
    #     };
    #   };
    # };
    # lvm_vg = {
    # };
  };
}
