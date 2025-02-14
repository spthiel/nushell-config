# config.nu
#
# Installed by:
# version = "0.102.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

$env.config.color_config.header = "lrb";
$env.config.color_config.bool = "white";
$env.config.color_config.date = "white";
$env.config.color_config.filesize = "white";
$env.config.color_config.row_index = "lrb";
$env.config.color_config.shape_custom = "light_green";
$env.config.color_config.shape_external = "cyan";
$env.config.color_config.shape_external_resolved = "lc";
$env.config.color_config.shape_filepath = "green";
$env.config.color_config.shape_string = "lh";

$env.config.show_banner = false;
$env.config.table.mode = "compact";
$env.config.history.sync_on_enter = true;
$env.config.completions.external.enable = true;
$env.config.shell_integration = {
        osc2: false
        osc7: false
        osc8: false
        osc9_9: false
        osc133: false
        osc633: false
        reset_application_mode: false
    };

source ~/.zoxide.nu
