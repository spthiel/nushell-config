# Nushell Environment Config File

def create_left_prompt [] {

    let user = ($env.USER)
    let host = (sys | get host.hostname)
    let dirPath = ($env.PWD | str replace $env.HOME "~" )

    let pathSegments = if (env | any {|$it| $it.name == PROMPT_PATH_SEGMENTS}) {$env.PROMPT_PATH_SEGMENTS} else {3}

    let splittedPath = ($dirPath | split row "/" )
    let path = ($splittedPath | last $pathSegments | str collect "/")

    let path = if ($splittedPath | last $pathSegments | get 0) != "~" {
        "/" + $path
    } else {$path}
    let path = if ($splittedPath | length) > $pathSegments {
        "⇜" + $path
    } else {$path}

    let path = ($path | ansi gradient --fgstart 0x9393ec --fgend 0x93ecec)

    let userhost = ($"(ansi lyb)($user)@($host)")

    let topLine = $"(ansi white)╭─╴($userhost) (ansi ly)($path)(ansi white) " + (create_git)
    let bottomLine = $"(ansi wb)╰─"

    $"($topLine)\n($bottomLine)"
}

def create_git [] {
    let isGit = (do -i {git rev-parse --is-inside-work-tree} | complete | get stdout | str trim)
    let out = if ($isGit == "true") {
        let branch = (git branch --show-current | str trim)
        let diffIndex = (do -i {git diff-index --cached HEAD} | complete | get stdout | str trim)
        let stagedChanges = ($diffIndex != "")
        let unstagedChanges = ((git diff-files) != "")
        let output = $"($branch)"
        let output = if $stagedChanges {$"($output)(ansi lg)*"} else {$output}
        let output = if $unstagedChanges {$"($output)(ansi lr)*"} else {$output}

        $"(ansi lp)<($output)(ansi lp)>"
    } else {
        ""
    }
    $out
}

def create_right_prompt [] {
    let time_segment = ([
        (date now | date format '%r')
    ] | str collect)

    let line = $"($time_segment)"
    let bottomLine = []

    let line = if ($env.LAST_EXIT_CODE > 0) {
        $"($line) (ansi rb)($env.LAST_EXIT_CODE) ↲"
    } else {$line}

    $line | str collect
}

# Use nushell functions to define your right and left prompt
let-env PROMPT_COMMAND = { create_left_prompt }
let-env PROMPT_COMMAND_RIGHT = { create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
let-env PROMPT_INDICATOR = { "$ " }
let-env PROMPT_INDICATOR_VI_INSERT = { ": " }
let-env PROMPT_INDICATOR_VI_NORMAL = { "〉" }
let-env PROMPT_MULTILINE_INDICATOR = { "↳ " }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
let-env ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
}

# Directories to search for scripts when calling source or use
#
# By default, <nushell-config-dir>/scripts is added
let-env NU_LIB_DIRS = [
    ($nu.config-path | path dirname | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
#
# By default, <nushell-config-dir>/plugins is added
let-env NU_PLUGIN_DIRS = [
    ($nu.config-path | path dirname | path join 'plugins')
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
let-env PATH = ($env.PATH | split row (char esep) | | append (open ($nu.config-path | path dirname | path join "path") | lines))

def convertcolor [$color] {
    let converted = (do -i {ansi $color});
    if ($converted | is-empty) {
        $color | into string;
    } else {
        $converted | str substring 2,-1;
    }
}

def grablscolors [] {
    let lscolors = (open (ls ($nu.config-path | path dirname | path join "lscolors.*") | get 0.name));
    let transposed = ($lscolors | transpose key value | update value {|c| convertcolor $c.value});
    $transposed | each {|it| $it.key + "=" + $it.value} | str join ":";
}

let-env LS_COLORS = grablscolors

source modules/_index.nu