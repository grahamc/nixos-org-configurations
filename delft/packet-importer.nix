{ config, lib, pkgs, ... }:
let
  importer = pkgs.callPackage ../hydra-packet-importer { };
in
{
  deployment.keys."hydra-packet-import.json" = {
    keyFile = ../hydra-packet-import.json;
    user = "hydra-packet";
  };

  users.extraUsers.hydra-packet =
    { description = "Hydra Packet Machine Importer";
      group = "hydra";
    };

  system.activationScripts.hydra-packet = lib.stringAfter [ "users" ]
    ''
      mkdir -m 0755 -p /var/lib/hydra/packet-import
      chown hydra-packet.hydra /var/lib/hydra/packet-import
      if [ ! -f /var/lib/hydra/packet-import ]; then
        touch  /var/lib/hydra/packet-import/machines
        chown hydra-packet.hydra /var/lib/hydra/packet-import/machines
        chmod 0644 /var/lib/hydra/packet-import/machines
      fi
      chown hydra-packet.hydra /var/lib/hydra/packet-import
    '';

  services.hydra-dev.buildMachinesFiles = [
    "/var/lib/hydra/packet-import/machines"
  ];

  systemd.services.hydra-packet-import = {
    path = with pkgs; [ openssh moreutils ];
    script = "${importer}/bin/hydra-packet-importer /run/keys/hydra-packet-import.json | sponge /var/lib/hydra/packet-import/machines";
    serviceConfig = {
      User = "hydra-packet";
      Group = "keys";
      SupplementaryGroups = [ "hydra" "keys" ];
      Type = "oneshot";
    };
  };

  systemd.timers.hydra-packet-import = {
    enable = true;
    description = "Update the list of Hydra machines from Packet.net";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
    };
  };
}
