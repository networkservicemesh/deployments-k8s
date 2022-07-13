# Get files that were added in the current branch
newfiles=$(git diff --name-only --diff-filter=A --merge-base main/main HEAD)
echo $newfiles

prefix="':!"
postfix="'"
exclude=""
for file in ${newfiles}; do
    exclude="${exclude} ${prefix}${file}${postfix}"
done

echo $exclude

eval "git diff --exit-code --name-only -- . ${exclude}"
echo $?