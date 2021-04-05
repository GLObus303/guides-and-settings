# Hyper

My currently used command line is Hyper. I find it the most convenient, yet there are many other alternatives like iTerm and so on.

- https://hyper.is/

On top of that and the whole core of the flow is oh my zsh shell - https://ohmyz.sh/. Which is an absolute game-changer.

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
alias dcu="docker-compose up"
alias dcd="docker-compose down"

// Project specific, the first one for proxy the second one for automating repeated process when creating PR.
alias mwwnxt='nohup /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --user-data-dir=/Users/lucizek/appdata/chrome-mwwnxt --proxy-server="http://127.0.0.1:8080" > ~/appdata/chrome.out &'
alias predlink='echo "link: https://$(git_current_branch)-profiles-single-page-application.mwwnxtpreprod.monster-next.com/en-us/profile/detail\n\nbranch(this goes to nginx): $(git_current_branch)" | pbcopy'
```
