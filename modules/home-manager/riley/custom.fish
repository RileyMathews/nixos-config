function gcb -a branch_name -d "make a new branch with worktrunk and zellij"
    wt switch -c $branch_name -x "zellij -s {{repo}}.{{branch}}"
end

zoxide init fish | source
direnv hook fish | source
