{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.taffybar;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.taffybar = {
      enable = mkEnableOption "Taffybar";

      package = mkOption {
        default = pkgs.taffybar;
        defaultText = literalExample "pkgs.taffybar";
        type = types.package;
        example = literalExample "pkgs.taffybar";
        description = "The package to use for the Taffybar binary.";
      };

      config = mkOption {
        default = null;
        defaultText = literalExample "null";
        type = types.nullOr types.path;
        example = literalExample "./files/taffybar.hs";
        description = "The file to use for the Taffybar config.";
      };
    };
  };

  config = mkIf config.services.taffybar.enable (
    mkMerge [
      {
        systemd.user.services.taffybar = {
          Unit = {
            Description = "Taffybar desktop bar";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${cfg.package}/bin/taffybar";
            Restart = "on-failure";
          };

          Install = { WantedBy = [ "graphical-session.target" ]; };
        };

        xsession.importedVariables = [ "GDK_PIXBUF_MODULE_FILE" ];
      }

      (mkIf (cfg.config != null) {
        systemd.user.services.taffybar.Unit.X-Restart-Triggers = [
          "${config.xdg.configFile."taffybar/taffybar.hs".source}"
        ];
        xdg.configFile."taffybar/taffybar.hs" = {
          source = cfg.config;
          onChange = "systemctl --user restart taffybar.service";
        };
      })
    ]
  );
}
