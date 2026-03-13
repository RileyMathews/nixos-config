# Planning work
When planning work. Make liberal use of the 'research' subagent when more information might be needed on how to do a particular task.

# Haskell
When working in haskell projects always prefer to use the ghciwatch magic comment method for testing.

NEVER use global commands that will recompile and run tests en mass. Always assume ghciwatch is running
and available and that you can use the magic comment for tests.

If using the magic comment method for testing seems to fail for any reason
do not fallback to other commands. Stop and ask the user to fix the environment.

