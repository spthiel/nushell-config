# Nushell Environment Config File

$env.LC_ALL = "en_US.UTF-8"

$env.HOSTNAME = (sys host | get hostname)

def create_left_prompt [] {

    let user = ($env.USER)
    let host = (sys host | get hostname)
    let dirPath = ($env.PWD | str replace $env.HOME "~" )

    let pathSegments = if ($env | columns | any {|$it| $it == "PROMPT_PATH_SEGMENTS"}) {$env.PROMPT_PATH_SEGMENTS} else {3}

    let splittedPath = ($dirPath | split row "/" )
    let path = ($splittedPath | last $pathSegments | str join "/")

    let path = if ($splittedPath | last $pathSegments | get 0) != "~" {
	if ($path | str starts-with "/") {
            $path
        } else {
            "/" + $path
        }
    } else {$path}

    let path = if ($splittedPath | length) > $pathSegments {
        "⇜" + $path
    } else {$path}

    let path = ((ansi lcb) + $path)

    let userhost = ($"(ansi lyb)($user)@($host)")

    let topLine = $"(ansi wb)╭─╴($userhost) (ansi ly)($path)(ansi white) " + (create_git) + " " + (createDDev)
    let bottomLine = $"(ansi wb)╰─"

    $"($topLine)\n($bottomLine)"
}

def createDDev [] {
    let ddev = (do -i {ddev status -j err> /dev/null} | str trim | from json)
    let out = if ($ddev | is-empty) {
        ""
    } else {
        let ddev = ($ddev | get raw)
        let url = ($ddev | get httpsURLs | where $it =~ ($env.HOSTNAME))
        let url = if ($url | is-empty) {
            $ddev | get httpsURLs | get 0
        } else {
            $url | get 0
        }
        let dbPort = ($ddev | get -i dbinfo.published_port)
        let dbPort = if ($dbPort | is-empty) {
            "none"
        } else {
            $dbPort
        }
        let nodeVersion = ($ddev | get nodejs_version)
        let phpVersion = ($ddev | get php_version)

        $" (ansi lp)<($url) DB:($dbPort) Node@($nodeVersion) Php@($phpVersion)>"
    }
    $out
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
        (date now | format date '%r')
    ] | str join)

    let line = $"($time_segment)"
    let bottomLine = []

    let line = if ($env.LAST_EXIT_CODE > 0) {
        $"($line) (ansi rb)($env.LAST_EXIT_CODE) ↲"
    } else {$line}

    $line | str join
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = { create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = { "$ " }
$env.PROMPT_INDICATOR_VI_INSERT = { ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = { "〉" }
$env.PROMPT_MULTILINE_INDICATOR = { "↳ " }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
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
$env.NU_LIB_DIRS = [
    ($nu.config-path | path dirname | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
#
# By default, <nushell-config-dir>/plugins is added
$env.NU_PLUGIN_DIRS = [
    ($nu.config-path | path dirname | path join 'plugins')
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
touch ($nu.config-path | path dirname | path join "path")
$env.PATH = ($env.PATH | split row (char esep) | | append (open ($nu.config-path | path dirname | path join "path") | lines))

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

$env.LS_COLORS = grablscolors

# const indexFile = ($nu.config-path | path dirname | path join "modules" "_index.nu")
# source $indexFilenu

# DDev jump
def "nu-complete ddev-jump" [] {
    ddev list -j | from json | get raw.name
}

def --env @ [project: string@"nu-complete ddev-jump"] {
    let ddev = (do -i {ddev describe $project -j} | complete | get stdout | str trim)
    let span = (metadata $project).span
    if ($ddev == "") {
        error make -u {
            msg: "Invalid project",
            label: {
                text: "Project doesnt exist",
                start: $span.start,
                end: $span.end
            }
        }
    }
    cd ($ddev | from json | get raw  | get approot)
}

def --env "docker ps" [
    --all (-a)           # Show all containers (default just shows running)
    --filter (-f):string # Filter output based on conditions provided
    --format:string      # Pretty-print containers using a Go template
    --last (-n):int      # Show n last created containers (includes all states) (default -1)
    --latest (-l)        # Show the latest created container (includes all states)
    --quiet (-q)         # Only display container IDs
    --size (-s)          # Display total file sizes
] {
    let $flags = ""
    let $flags = if ($all) { $"($flags) -a" } else { $flags }
    let $flags = if ($filter) { $"($flags) -f ($filter)" } else { $flags }
    let $flags = if (not ($format | is-empty)) { $"($flags) --format ($format)" } else { $flags }
    let $flags = if (not ($last | is-empty)) { $"($flags) -n ($last)"} else { $flags }
    let $flags = if ($latest) { $"($flags) -l" } else { $flags }
    let $flags = if ($quiet) { $"($flags) -q" } else { $flags }
    let $flags = if ($size) { $"($flags) -s" } else { $flags }
    let $flags = ($flags | str trim);
    if ($flags != "") {
        ^docker ps ($flags | split row " ") | from ssv -a;
    } else {
        ^docker ps | from ssv -a
    }
}

def --env dps [] {
    ^docker ps -a | from ssv -a
}

# QR Code Scan
def --env scanqr [] {
    clear;
    mut out = [];
    while true {
        let new = (import -silent -window root bmp:- | zbarimg - -q -Sposition=false | lines | each {|it| let idx = ($it | str index-of ":");$it | str substring ($idx + 1).. })
        $out = ($out | prepend $new | uniq)
        let echo = ($out | each {|it| if ($new | any {|itnew| $itnew == $it}) {$"(ansi lg)($it)"} else {$"(ansi lr)($it)"} })
        print $echo
	echo "\e[0;0f"
        sleep 1sec;
    }
}

def --env fuck [] {
    $env.TF_ALIAS = "fuck";
    $env.PYTHONIOENCODING = "utf-8";
    let res = thefuck (history | last | get "command");
    if (not ($res | is-empty)) {
        $res | save -f /tmp/fuck.nu;
        nu /tmp/fuck.nu;
        rm /tmp/fuck.nu;
    }
}

def --env cve [
  --ticket (-t): string # Override ticket number
] {
    if (not ("gradlew" | path exists)) {
        error make {
           msg: "Not in project root"
        };
    }
    let ticketNumber = if ($ticket | is-empty) {
        git branch --show-current 
            | parse -r "(?<ticket>EAC-\\d+)" 
            | get ticket.0;
    } else {
        if ($ticket | str starts-with "EAC") {
            $ticket;
        } else {
            $"EAC-($ticket)";
        }
    }
    
    print $"Description of ticket ($ticketNumber):";
    let description = (input);

    if (($description | is-empty) or ($description == "exit")) {
    } else {

        let history = {
            id: $ticketNumber,
            date: (date now | format date "%Y-%m-%d"),
            tags: [],
            changeDesc: $description
        };

        echo (["history" (date now | format date "%Y") (date now | format date "%m") $"($ticketNumber).json"] | path join);

        $history 
            | save (["history" (date now | format date "%Y") (date now | format date "%m") $"($ticketNumber).json"] | path join);
    }

}
