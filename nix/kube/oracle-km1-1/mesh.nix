{
version = "v1";
subnets = [
    {
    name = "simple";
    endpoints = [
        {
        # No match mean match any
        port = 51820;
        }
    ];
    }
];
peers = [
    {
      name = "node1";
      subnets = {
          simple = {
          listenPort = 51820;
          # no ipAddresses field will auto generate an IPv6 address
          };
      };
      publicKey = "kdyzqV8cBQtDYeW6R1vUug0Oe+KaytHHDS7JoCp/kTE=";
      privateKeyFile = "/etc/wg-key";
      endpoints = [
          {
          # no match can be any
          ip = "node1";
          }
      ];
    }
    {
      name = "node2";
      subnets = {
          simple = {
          listenPort = 51820;
          };
      };
      publicKey = "ztdAXTspQEZUNpxUbUdAhhRWbiL3YYWKSK0ZGdcsMHE=";
      privateKeyFile = "/etc/wg-key";
      endpoints = [
          {
          # no match field means match all peers
          ip = "node2";
          }
      ];
    }
];
connections = [
    {
    a = [{type= "subnet"; rule = "is"; value = "simple";}];
    b = [{type= "subnet"; rule = "is"; value = "simple";}];
    }
];
}