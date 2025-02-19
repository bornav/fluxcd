{ disks ? [ "/dev/vdb" ], ... }: 
# { lib, ... }:
{
 disko.devices = {
  disk.disk1 = {
    device = builtins.elemAt disks 0;
    # device = lib.mkDefault "/dev/sda";
    type = "disk";
    content = {
     type = "gpt";
     partitions = {
      boot = {
        name = "boot";
        size = "1M";
        type = "EF02";
      };
      esp = {
        name = "ESP";
        size = "500M";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
        };
      };
      root = {
        name = "root";
        size = "100G";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      };
      storage = {
        name = "storage";
        size = "100%";
        content = {
          type = "filesystem";
          format = "xfs";
          # mountpoint = "/";
        };
      };
     };
    };
   };
  # disk.disk2 = {
  #   device = "/dev/sdb";
  #   type = "disk";
  #   content = {
  #    type = "gpt";
  #    partitions = {
  #     storage2 = {
  #       name = "storage2";
  #       size = "100%";
  #       content = {
  #         type = "filesystem";
  #         format = "xfs";
  #         # mountpoint = "/";
  #       };
  #     };
  #    };
  #   };
  #  };
  };
}