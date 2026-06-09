{
  pkgs,
  config,
  lib,
  ...
}:

{
  sops.secrets."wifi" = {
    sopsFile = ../secrets/wifi.yaml;
  };

  networking = {

    networkmanager = {

      enable = true;

      ensureProfiles = {

        environmentFiles = [ config.sops.secrets."wifi".path ];

        profiles = {

          "eduroam" = {
            connection = {
              id = "eduroam";
              type = "wifi";
              autoconnect = true;
            };
            wifi = {
              mode = "infrastructure";
              ssid = "eduroam";
            };
            wifi-security = {
              key-mgmt = "wpa-eap";
            };
            "802-1x" = {
              identity = "$EDUROAM_IDENTITY";
              anonymous-identity = "anonymous@zcu.cz";
              ca-cert = "../nixos/certs/isrgrootx1.der";
              eap = "peap";
              phase2-auth = "mschapv2";
              password = "$EDUROAM_PASSWORD";
            };
            ipv4 = {
              method = "auto";
            };
            ipv6 = {
              method = "auto";
            };
          };

          "Stybr" = {
            connection = {
              id = "Stybr";
              type = "wifi";
              autoconnect = true;
            };
            wifi = {
              mode = "infrastructure";
              ssid = "Stybr";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$STYBR_PSK";
            };
            ipv4 = {
              method = "auto";
            };
            ipv6 = {
              method = "auto";
            };
          };

          "stybr-hotspot" = {
            connection = {
              id = "stybr-hotspot";
              type = "wifi";
              autoconnect = true;
            };
            wifi = {
              mode = "infrastructure";
              ssid = "stybr";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$STYBR_HOTSPOT_PSK";
            };
            ipv4 = {
              method = "auto";
            };
            ipv6 = {
              method = "auto";
            };
          };
        };

      };

    };
  };
}
