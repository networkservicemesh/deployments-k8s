newfiles=$(git diff --name-only HEAD $(git merge-base HEAD main/main))
echo $newfiles

prefix="':!"
postfix="'"
exclude=""
for file in ${newfiles}; do
    exclude="${exclude} ${prefix}${file}${postfix}"
done

echo $exclude

