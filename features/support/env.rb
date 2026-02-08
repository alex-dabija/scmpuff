require 'aruba/cucumber'

Before do
  author_name  = "SCM Puff"
  author_email = "scmpuff@test.local"
  set_environment_variable 'GIT_AUTHOR_NAME',     author_name
  set_environment_variable 'GIT_COMMITTER_NAME',  author_name
  set_environment_variable 'GIT_AUTHOR_EMAIL',    author_email
  set_environment_variable 'GIT_COMMITTER_EMAIL', author_email
end

# since tmp/aruba is nested within the git repo of this program, we need to
# be somewhere else to test behavior of the binary when outside the git repo.
Before('@outside-repo') do
  tmpdir = Dir.mktmpdir("aruba")
  cd tmpdir
end

When(/I initialize scmpuff in `(.*)`/) do |shell|
  if shell == "fish"
    type %{scmpuff init -w --shell=fish | source}
  elsif shell == "nu"
    type %{scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu}
    type %{source /tmp/scmpuff_init.nu}
  else
    type %{eval "$(scmpuff init -ws)"}
  end
end

When(/I close the shell `(.*)`/) do |shell|
  if shell == "nu"
    type "exit $env.LAST_EXIT_CODE"
  elsif shell == "fish"
    type "exit $status"
  else
    type "exit $?"
  end
  close_input
  step("I stop the command \"#{shell}\"")
end

# Nushell requires a TTY for interactive mode, so we cannot use aruba's
# interactive stdin-pipe approach. Instead, we collect commands into a script
# and run them with `nu -c`.
Before('@nu-script') do
  @nu_commands = []
end

# Collect a nushell command to be run later
When(/^I add nushell command `(.*)`$/) do |cmd|
  @nu_commands << cmd
end

When(/^I add nushell command:$/) do |cmd|
  @nu_commands << cmd.to_s
end

# Execute all collected nushell commands as a single script.
# The working directory is set to aruba's current directory.
#
# Nushell validates `source` paths at parse time, before any commands execute.
# To support the pattern where a command generates a file that is then sourced,
# we extract commands that pipe to `save` and run them in a preliminary step so
# the files exist when nushell parses the main script's `source` directives.
When(/^I run the nushell commands$/) do
  cwd = expand_path(".")

  pre_commands = []
  main_commands = []
  @nu_commands.each do |cmd|
    if cmd =~ /\|\s*save\s/
      pre_commands << cmd
    else
      main_commands << cmd
    end
  end

  # Run file-generating commands first so `source` can find them at parse time
  if pre_commands.any?
    pre_script = "cd #{cwd}\n" + pre_commands.join("\n")
    @nu_pre_script_path = "/tmp/_nu_pre_script_#{$$}.nu"
    File.write(@nu_pre_script_path, pre_script)
    run_command_and_stop("nu #{@nu_pre_script_path}", fail_on_error: false)
  end

  # Write the main script to /tmp to avoid polluting the git repo under test
  script = "cd #{cwd}\n" + main_commands.join("\n")
  @nu_script_path = "/tmp/_nu_test_script_#{$$}.nu"
  File.write(@nu_script_path, script)

  run_command_and_stop("nu #{@nu_script_path}", fail_on_error: false)
end

After('@nu-script') do
  File.delete(@nu_pre_script_path) if @nu_pre_script_path && File.exist?(@nu_pre_script_path)
  File.delete(@nu_script_path) if @nu_script_path && File.exist?(@nu_script_path)
end
