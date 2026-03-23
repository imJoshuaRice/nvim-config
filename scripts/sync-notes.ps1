cd $env:USERPROFILE\notes
git pull --rebase
git add -A
git commit -m "sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>$null
git push
