#!/bin/bash

versions=$(npm view @nrwl/nx versions --json)

versions=${versions//\"/}
versions=${versions//\[/}
versions=${versions//\]/}
versions=${versions//\,/}

versions=(${versions})

blacklist=()

lastVersion="0.0.0"
rebaseNeeded=false

for version in "${versions[@]}"
do

  if [[ " ${blacklist[@]} " =~ " ${version} " ]]
  then
    echo "Skipping blacklisted ${version}"
    continue
  fi

  if [ `git branch --list ${version} ` ]
  then
    echo "${version} already generated."
    git checkout ${version}
    if [ ${rebaseNeeded} = true ]
    then
      git rebase --onto ${lastVersion} head~ ${version} -X theirs
      diffStat=`git --no-pager diff head~ --shortstat`
      git push origin ${version} -f
      diffUrl="[${lastVersion}...${version}](https://github.com/beeman/nx-workspace-diff/compare/${lastVersion}...${version})"
      git checkout master
      # rewrite stats in README after rebase
      sed -i "" "/^${version}|/ d" README.md
      sed -i '' 's/----|----|----/----|----|----\
NEWLINE/g' README.md
      sed -i "" "s@NEWLINE@${version}|${diffUrl}|${diffStat}@" README.md
      git commit -a --amend --no-edit
      git checkout ${version}
    fi
    lastVersion=${version}
    continue
  fi

  echo "Generate ${version}"
  rebaseNeeded=true
  git checkout -b ${version}
  # delete app
  rm -rf new-workspace
  # generate app with new CLI version
  npx -p @nrwl/nx@${version} create-nx-workspace new-workspace --skip-install
  git add new-workspace
  git commit -am "chore: version ${version}"
  diffStat=`git --no-pager diff head~ --shortstat`
  git push origin ${version} -f
  git checkout master
  diffUrl="[${lastVersion}...${version}](https://github.com/beeman/nx-workspace-diff/compare/${lastVersion}...${version})"
  # insert a row in the version table of the README
  sed -i "" "/^${version}|/ d" README.md
  sed -i '' 's/----|----|----/----|----|----\
NEWLINE/g' README.md
  sed -i "" "s@NEWLINE@${version}|${diffUrl}|${diffStat}@" README.md
  # commit
  git commit -a --amend --no-edit
  git checkout ${version}
  lastVersion=${version}

done

git checkout master
git push origin master -f
