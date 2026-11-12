alias gitwb="git branch -vv"
alias gitprep="git add ."
alias gitfr="git fetch;git rebase origin/develop"
alias gitl="git log -n 20"
alias prunebranch="git fetch -p; git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D"
alias p="pnpm"
alias python="python3"
alias pip="pip3"
alias gitrev="git difftool origin/main...HEAD"
alias aicost="npx codeburn"
alias opencodeauth="cat ~/.local/share/opencode/auth.json"

# Stage the current directory, commit with a message, and push.
# gacp 'my commit message'
gacp() {
  if [[ $# -ne 1 || -z "$1" ]]; then
    print -u2 "Usage: gacp 'commit message'"
    return 1
  fi
  git add . && git commit -m "$1" && git push
}

# Vercel GTM env vars and project config (run from the destination repo root).
alias vcge='cp ../gtm/apps/gtm-workflows/.env.local ./apps/gtm-workflows/.env.local && mkdir -p ./apps/gtm-workflows/.vercel && cp -R ../gtm/apps/gtm-workflows/.vercel/. ./apps/gtm-workflows/.vercel/'
# Stop Next.js, Vercel, Vite, and Turbo dev servers across local repos.
alias vck='pkill -TERM -f "[n]ext dev|[n]ext-server|[v]ercel dev|[v]ite( |$)|[t]urbo dev"'
