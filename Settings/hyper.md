# Hyper

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
alias zshconfig="code ~/.zshrc"
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
alias ohmyzsh="code ~/.oh-my-zsh"
```
