$env.SCMPUFF_GIT_CMD = ($env | get -o SCMPUFF_GIT_CMD | default (which -a git | where type == external | get 0.path))

def --env --wrapped git [...rest: string] {
    if ($rest | is-empty) {
        ^$env.SCMPUFF_GIT_CMD
        return
    }
    match $rest.0 {
        "commit" | "blame" | "log" | "rebase" | "merge" => {
            ^scmpuff exec -- $env.SCMPUFF_GIT_CMD ...$rest
        }
        "checkout" | "diff" | "rm" | "reset" | "restore" => {
            ^scmpuff exec --relative -- $env.SCMPUFF_GIT_CMD ...$rest
        }
        "add" => {
            ^scmpuff exec -- $env.SCMPUFF_GIT_CMD ...$rest
            scmpuff_status
        }
        _ => {
            ^$env.SCMPUFF_GIT_CMD ...$rest
        }
    }
}
