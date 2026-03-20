function gcb -a branch_name -d "make a new branch with worktrunk and zellij"
    wt switch -c $branch_name -x "zellij -s {{repo}}.{{branch}}"
end

function gw -d "run ghciwatch with additional fields for my local workflow"
    services up
    make ghciwatch | tee .devel-logs/output.txt
end

zoxide init fish | source
direnv hook fish | source
wt config shell init fish | source
