
def pathFile [] {
    $nu.config-path | path dirname | path join "path";
} 

export def-env addpath [path: path] {
    let-env PATH = ($env.PATH | split row (char esep) | append $path);
    "\n" + $path | save --append (pathFile);
}

export def-env rmpath [path: path] {
    let-env PATH = ($env.PATH | split row (char esep) | filter {|it| $it != $path});
    open (pathFile) | lines | filter {|it| $it != $path} | uniq | str join "\n" | save -f (pathFile);
}