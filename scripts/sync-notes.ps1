cd $env:USERPROFILE\notes
git add -A
git commit -m "sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push
