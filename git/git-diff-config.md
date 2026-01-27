# Git Diffs

Uses Zed to pull up all file diff's for a particular branch.

```
git config --global diff.tool zed
git config --global difftool.prompt false
git config --global difftool.zed.cmd 'zed --diff "$LOCAL" "$REMOTE"'
git difftool origin/main...HEAD
```
