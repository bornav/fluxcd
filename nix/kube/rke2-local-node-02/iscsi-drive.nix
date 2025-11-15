{ config, lib, system, inputs, host, vars, pkgs, pkgs-unstable, ... }: # TODO remove system, only when from all modules it is removed
{
  services.openiscsi = {
    enable = true;
    discoverPortal = [ "10.2.11.200:3260" ];
    name = lib.mkForce "iqn.2005-10.org.freenas.ctl:iscsi-worker-local-02";
  };
  systemd.services.iscsi-login-lingames = {
    description = "Login to iSCSI target iqn.2005-10.org.freenas.ctl:iscsi-worker-local-02";
    after = [ "network.target" "iscsid.service" ];
    wants = [ "iscsid.service" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.openiscsi}/bin/iscsiadm -m discovery -t sendtargets -p 10.2.11.200";
      ExecStart = "${pkgs.openiscsi}/bin/iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:iscsi-worker-local-02 -p 10.2.11.200 --login";
      ExecStop = "${pkgs.openiscsi}/bin/iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:iscsi-worker-local-02 -p 10.2.11.200 --logout";
      Restart = "on-failure";
      RemainAfterExit = true;
    };
    wantedBy = [ "multi-user.target" ];
  }; 


}
