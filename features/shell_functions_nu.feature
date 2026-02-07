Feature: scmpuff_status function (nushell)
  The scmpuff_status shell function wraps the underlying
  `scmpuff status` command, passing along the `--filelist` option and then
  parsing the results to set environment variables in the current shell.

  Nushell requires a TTY for interactive mode, so these tests use a
  script-based approach with `nu -c` instead of aruba's interactive mode.

  Background:
    Given a mocked home directory

  @outside-repo @nu-script
  Scenario: Handle error conditions from wrapped binary command
    When I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command `exit $env.LAST_EXIT_CODE`
    And I run the nushell commands
    Then the exit status should be 128
    And the stderr should contain:
      """
      Not a git repository (or any of the parent directories)
      """

  @nu-script
  Scenario: Basic functionality works with shell wrapper
    Given I am in a git repository
    When I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I run the nushell commands
    Then the exit status should be 0
    And the output should contain "No changes (working directory clean)"

  @nu-script
  Scenario: Sets proper environment variables in shell
    Given I am in a complex working tree status matching scm_breeze tests
      And the scmpuff environment variables have been cleared
    When I add nushell command `scmpuff init --shell=nu --wrap=false | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command:
      """
      print $"e1:($env | get -o e1 | default '')"
      print $"e2:($env | get -o e2 | default '')"
      print $"e3:($env | get -o e3 | default '')"
      print $"e4:($env | get -o e4 | default '')"
      print $"e5:($env | get -o e5 | default '')"
      """
    And I run the nushell commands
    Then the output should match /^e1:.*new_file$/
      And the output should match /^e2:.*deleted_file$/
      And the output should match /^e3:.*new_file$/
      And the output should match /^e4:.*untracked_file$/
      And the output should match /^e5:$/

  @nu-script
  Scenario: Sets proper environment variables in shell with weird filenames
    Given I am in a git repository
      And an empty file named "aa bb"
      And an empty file named "bb|cc"
      And an empty file named "cc*dd"
    When I add nushell command `scmpuff init --shell=nu --wrap=false | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command:
      """
      print $"e1:($env | get -o e1 | default '')"
      print $"e2:($env | get -o e2 | default '')"
      print $"e3:($env | get -o e3 | default '')"
      print $"e4:($env | get -o e4 | default '')"
      """
    And I run the nushell commands
    Then the output should match /^e1:.*aa bb$/
      And the output should match /^e2:.*bb\|cc$/
      And the output should match /^e3:.*cc\*dd$/
      And the output should match /^e4:$/

  @nu-script
  Scenario: Clears extra environment variables from before
    Given I am in a complex working tree status matching scm_breeze tests
      And the scmpuff environment variables have been cleared
    When I add nushell command `scmpuff init --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command `git add new_file`
    And I add nushell command `git commit -m 'so be it'`
    And I add nushell command `scmpuff_status`
    And I add nushell command:
      """
      print $"e1:($env | get -o e1 | default '')"
      print $"e2:($env | get -o e2 | default '')"
      print $"e3:($env | get -o e3 | default '')"
      print $"e4:($env | get -o e4 | default '')"
      print $"e5:($env | get -o e5 | default '')"
      """
    And I run the nushell commands
    Then the output should match /^e1:.*deleted_file$/
      And the output should match /^e2:.*untracked_file$/
      And the output should match /^e3:$/
      And the output should match /^e4:$/
      And the output should match /^e5:$/

  @nu-script
  Scenario: default SCMPUFF_GIT_CMD is set to absolute path of a git command
    When I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `print $env.SCMPUFF_GIT_CMD`
    And I run the nushell commands
    Then the output should match %r<^/.+/git$>

  @nu-script
  Scenario: SCMPUFF_GIT_CMD respects existing environment variables
    When I add nushell command `$env.SCMPUFF_GIT_CMD = "/foo/hub"`
    And I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `print $env.SCMPUFF_GIT_CMD`
    And I run the nushell commands
    Then the output should contain exactly "/foo/hub"
