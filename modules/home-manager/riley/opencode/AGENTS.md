# Planning work
When planning work. Make liberal use of the 'research' subagent when more information might be needed on how to do a particular task.

# Verification
In my personal projects I typically use a 'Justfile' for task running.
When an `agent-full-verify` task is present that recipe should be used as the single source of truth for how you should verify the project.
That task should run all the needed tests, linters, and other checks to verify the project is in a good state.
NEVER modify the `agent-full-verify` task. That task is created and maintained by the operator to ensure that the project is in a good state.
When the `agent-full-verify` task is present it should ALWAYS be run and be successful before any work is considered complete.
You may run individual linters, tests, or other checks as you see fit during the work process, but the `agent-full-verify` task is the single source of truth for what is needed to verify the project is in a good state.

# TMP File usage
If you ever need to save something to a tmp file for reading i.e. fetching a web file then disecting it locally or writing a PR body to write into a pr creation command.
Use a local directory .tmp to save this file to. If the .tmp directory isn't in the gitignore when you do this go ahead and add it. That way you can continue without
having to ask for external directory access.

# Language specific workflows
The following are rules for working in projects of a specific language.
These are only here whenever I have specific quirks I want to follow that would deviate from
typical agent behavior. If a language isn't listed here don't worry about it.
But for the languages that are here ensure you follow these steps very closely when working on it.

## Haskell

### Building projects
I have created a workflow specific to agents to build haskell projects.
This workflow involves me as the operator starting a build server 'ghciwatch' in the background.
ghciwatch will automatically compile files and read magic comments to run tests when files are saved.
I have written a script `check-haskell-build-status-agent` that you must use to check the build status.
It will wait for the current compilation cycle to finish and then output the logs from the last build cycle along with test output if any were run.
`check-haskell-build-status-agent` also checks that the ghciwatch process is running as expected and will tell you to alert the operator when something is wrong.
If the script says something is wrong STOP IMMEDIATELY and report the error to me as the operator. Do not try to investigate these issues yourself.
IMPORTANT NOTE: ghciwatch currently has a bug where it will likely not pick up file changes while it is compiling another change.
If something seems off about the output like a file not picking up a change in another file then try re-touching the file to trigger compilation again before 
assuming there is an actual code issue.

NEVER run other commands to build or test Haskell projects. My agents workflow is specifically crafted to work with the
`check-haskell-build-status-agent` script and the ghciwatch workflow.
Running other commands will cause problems and may break the workflow.

### Running tests
- Ignore any specific project instructions for running tests.
- To run tests add the `-- $> hspec spec` magic comment to a file then `check-haskell-build-status-agent` will run that test file for you. The comment should go right above the spec function.
- NEVER use the 'test-by-module' command to run tests. It is not compatible with your workflow and will cause problems. Always use the `-- $> hspec spec` magic comment instead.

<IMPORTANT>
ALWAYS use `check-haskell-build-status-agent` to build and check haskell projects.
Even if project specific documentation says to use another method only use `check-haskell-build-status-agent`.
If `check-haskell-build-status-agent` appears to be having problems STOP IMMEDIATELY, report the issue, and await further instructions.
</IMPORTANT>
