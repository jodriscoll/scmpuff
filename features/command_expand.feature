Feature: command expansion at command line

  Background:
    Given I override the environment variables to:
      | variable | value |
      | e1       | a.txt |
      | e2       | b.txt |
      | e3       | c.txt |
      | e4       | d.txt |
      | e5       | e.txt |
      | e6       | f.txt |

  Scenario: Expand single digit case
    Important: note we check for an exact match here, because a line feed
    should not exist at the end of the output.

    When I successfully run `scmpuff expand 1`
    Then the output should contain exactly "a.txt"

  Scenario: Expand multiple digit case
    When I successfully run `scmpuff expand 1 2 6`
    Then the output should match /a.txt\tb.txt\tf.txt/

  Scenario: Expand complex case with range
    When I successfully run `scmpuff expand 6 3-4 1`
    Then the output should match /f.txt\tc.txt\td.txt\ta.txt/

  Scenario: Dont expand files or directories with numeric names
    Given an empty file named "1"
    Given a directory named "2"
    When I successfully run `scmpuff expand 3 2 1`
      Then the output should contain "c.txt"
      But the output should not contain "b.txt"
      And the output should not contain "a.txt"

  Scenario: Dont interfere with CLI "options" that are passed along after `--`
    When I successfully run `scmpuff expand -- git foo -x 1`
    Then the output should match /git\tfoo\t-x\ta.txt/

  Scenario: Make sure args with spaces get escaped on way back
    When I successfully run `scmpuff expand -- git xxx "foo bar" 1`
    Then the output should match /git\txxx\tfoo\\ bar\ta.txt/

  Scenario Outline: Verify filenames with stupid characters are properly escaped
    Given I override the environment variables to:
      | variable | value      |
      | e1       | <filename> |
    When I successfully run `scmpuff expand 1`
    Then the output should contain exactly "<escaped>"
    Examples:
      | filename       | escaped          |
      | so(dumb).jpg   | so\(dumb\).jpg   |
      | hi mom.txt     | hi\ mom.txt      |
      | "x.txt         | \"x.txt          |

  @wip
  Scenario: Don't get screwed up if filename contains a | symbol
    Given PENDING

  Scenario: Allow user to specify --relative paths
    Given a directory named "foo"
      And a directory named "foo/bar"
      And an empty file named "xxx.jpg"
      And I cd to "foo/bar"
    Given I override environment variable "e1" to the absolute path of "xxx.jpg"
    When I successfully run `scmpuff expand 1`
    Then the stdout from "scmpuff expand 1" should contain "/tmp/aruba/xxx.jpg"
    When I successfully run `scmpuff expand -r -- 1`
    Then the stdout from "scmpuff expand -r -- 1" should contain "../../xxx.jpg"
