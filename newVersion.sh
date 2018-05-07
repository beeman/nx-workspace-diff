#!/bin/bash
repository="@nrwl/schematics"

versions=$(npm view ${repository} versions --json)

versions=${versions//\"/}
versions=${versions//\[/}
versions=${versions//\]/}
versions=${versions//\,/}

versions=(${versions})

# pre 0.8.0 did not have 'create-nx-workspace'
blacklist=(0.0.1 0.0.2 0.0.3 0.0.4 0.0.5 0.0.6 0.0.7 0.0.8 0.1.0-beta.0
    0.1.0-beta.1 0.1.0 0.1.1 0.2.0 0.2.1 0.2.2 0.3.0 0.4.0 0.5.0 0.5.1 0.5.2
    0.5.3 0.5.4 0.5.5 0.5.6 0.5.7 0.5.8 0.5.9 0.6.0 0.6.1 0.6.2 0.6.3 0.6.4
    0.6.5 0.6.6 0.6.7 0.6.8 0.6.9 0.6.10 0.6.11 0.6.12 0.6.13 0.6.14 0.6.15
    0.6.16 0.6.17 0.6.18 0.6.19 0.6.20 0.7.0-beta.1 0.7.0-beta.2 0.7.0-beta.3
    0.7.0 0.7.1 0.7.2 0.7.3 0.7.4 0.8.0-beta.1 0.8.0-beta.2 0.8.0-beta.3
    0.8.0-beta.4 0.8.0-beta.5 0.8.0-beta.6
)

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
  rm -rf sandbox
  # generate app with new CLI version
  npx -p ${repository}@${version} create-nx-workspace sandbox
  cd sandbox
  ng generate app sandbox-app
  ng generate lib sandbox-lib
  cd -
  git add sandbox
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
