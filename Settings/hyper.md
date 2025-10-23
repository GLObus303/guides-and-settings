# Hyper

[**<- Back to main**](../README.md)

My currently used command line is Hyper. I find it the most convenient, yet there are many other alternatives like iTerm and so on.

- https://hyper.is/

On top of that and the whole core of the flow is oh my zsh shell - https://ohmyz.sh/. Which is an absolute game-changer.

Theme & plugins

```
ZSH_THEME="robbyrussell"
plugins=(tig yarn npm git wd docker)
```

Aliases

```
alias zshconfig="cursor ~/.zshrc"
alias c="clear"
alias la="ls -lA"
alias gits="git status"
alias gita="git add ."
alias gitc="git commit -m"
alias gitf="git fetch --all"
alias gitca="git commit --amend"
alias gitcan="git commit --amend --no-edit"
alias ..="cd .."
alias gisu="git push --set-upstream origin $(git_current_branch)"
alias ohmyzsh="cursor ~/.oh-my-zsh"
```

Personal, useless for most:

```
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH
export PATH=$PATH:/Users/lucizek/go/bin
export PATH="/opt/homebrew/opt/ansible@8/bin:$PATH"
export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


alias dcu="docker-compose up"
alias dcd="docker-compose down"

alias predlink='echo "link: https://$(git_current_branch)-profiles-single-page-application.mwwnextapppreprod-us.monster-next.com/en-us/profile/detail\n\nbranch(this goes to nginx): $(git_current_branch)" | pbcopy'
alias createjob="java -jar ~/Documents/postJobTool.jar"
alias cleanplay="rm -rf /var/folders/q6/x1pqm2y56jzfwbmc5kpq1vsm0000gr/T/playwright-transform-cache-504/"
alias deployrun="git checkout master && git pull && git checkout deploy-master && git reset --hard origin/master && yarn && yarn build:prod && git add . && git commit -m 'Deploy master' && git push -f"
alias clean300="kill -9 $(lsof -ti:3000)"

alias gcn="git commit --no-edit"
alias cbr='echo "document.cookie = \"cbr-$(basename $(pwd))=$(git_current_branch | tr "[:upper:]" "[:lower:]");path=/\"" | pbcopy'
```
