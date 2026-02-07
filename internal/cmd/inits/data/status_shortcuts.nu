def --env scmpuff_status [...args: string] {
    scmpuff_clear_vars
    let output = try {
        (^scmpuff status --filelist ...$args)
    } catch {
        return
    }
    let lines = ($output | lines)
    if ($lines | is-empty) { return }
    let file_line = ($lines | first)
    if ($file_line | str trim) != "" {
        let files = ($file_line | split row "\t")
        mut env_vars = {}
        for item in ($files | enumerate) {
            $env_vars = ($env_vars | insert $"e($item.index + 1)" $item.item)
        }
        load-env $env_vars
    }
    $lines | skip 1 | each { |line| print $line }
    null
}

def --env scmpuff_clear_vars [] {
    let vars = ($env | columns | where { |it| $it =~ '^e\d+$' })
    if not ($vars | is-empty) {
        mut to_clear = {}
        for v in $vars {
            $to_clear = ($to_clear | insert $v "")
        }
        load-env $to_clear
    }
}
