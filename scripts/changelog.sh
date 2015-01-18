TAG1=$(git describe --abbrev=0 --tags `git rev-list --tags --max-count=2` | head -n 1)
TAG2=$(git describe --abbrev=0 --tags `git rev-list --tags --max-count=2` | tail -n 1)

git log --no-merges --format="* %h %s" ${TAG2}...${TAG1} > CHANGELOG.txt