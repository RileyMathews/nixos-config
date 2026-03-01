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
