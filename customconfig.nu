$env.config.color_config.header = lrb;
$env.config.color_config.bool = white;
$env.config.color_config.date = white;
$env.config.color_config.filesize = white;
$env.config.color_config.row_index = lrb;
$env.config.color_config.shape_custom = light_green;
$env.config.color_config.shape_external = cyan;
$env.config.color_config.shape_external_resolved = lc;
$env.config.color_config.shape_filepath = green;
$env.config.color_config.shape_string = lh;

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
