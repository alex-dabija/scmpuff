Feature: optional wrapping of normal git cmds in the shell (nushell)
  In order to verify the nushell git wrappers work correctly
  I want to make sure they intercept and wrap naked git commands properly

  Background:
    Given a mocked home directory

  @nu-script
  Scenario: Wrapped `git add` adds by number and echos status after
    Given I am in a git repository
      And a 4 byte file named "foo.bar"
      And a 4 byte file named "bar.foo"
    When I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command `git add 1`
    And I run the nushell commands
    Then the output should contain:
      """
      # On branch: main  |  [*] => $e*
      #
      ➤ Changes to be committed
      #
      #       new file:  [1] bar.foo
      #
      ➤ Untracked files
      #
      #      untracked:  [2] foo.bar
      #
      """

  @nu-script
  Scenario: Wrapped `git add` can handle files with spaces properly
    Given I am in a git repository
      And an empty file named "file with spaces.txt"
    When I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command `git add 1`
    And I run the nushell commands
    Then the exit status should be 0
    And the output should match /new file:\s+\[1\] file with spaces.txt/

  @nu-script
  Scenario: Wrapped `git reset` can handle files with spaces properly
    Given I am in a git repository
      And an empty file named "file with spaces.txt"
      And I successfully run `git add "file with spaces.txt"`
    When I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command `git reset 1`
    And I run the nushell commands
    Then the exit status should be 0
    When I run `scmpuff status`
    Then the stdout from "scmpuff status" should contain:
      """
      untracked:  [1] file with spaces.txt
      """

  @nu-script @recent-git-only
  Scenario: Wrapped `git restore` works
    Given I am in a git repository
      And a 2 byte file named "foo.bar"
      And I successfully run `git add foo.bar`
      And I successfully run `git commit -m "initial commit"`
      And a 4 byte file named "foo.bar"
      And I successfully run `git add foo.bar`
    When I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command `git restore --staged 1`
    And I run the nushell commands
    Then the exit status should be 0
    When I run `scmpuff status`
    Then the stdout from "scmpuff status" should contain:
      """
      ➤ Changes not staged for commit
      #
      #       modified:  [1] foo.bar
      """

  @nu-script
  Scenario: Wrapped `git add` can handle shell variable expansion
    Given I am in a git repository
      And an empty file named "file with spaces.txt"
      And an empty file named "file2.txt"
      And an empty file named "untracked file.txt"
    When I add nushell command `scmpuff init -w --shell=nu | save -f /tmp/scmpuff_init.nu`
    And I add nushell command `source /tmp/scmpuff_init.nu`
    And I add nushell command `scmpuff_status`
    And I add nushell command `let FILE = "file with spaces.txt"`
    And I add nushell command `git add $FILE 2`
    And I run the nushell commands
    And the output should contain:
      """
      new file:  [1] file with spaces.txt
      """
    And the output should contain:
      """
      new file:  [2] file2
      """
    And the output should contain:
      """
      untracked:  [3] untracked file.txt
      """
    Then the exit status should be 0
