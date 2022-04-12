{{/* prints params required by reviewdog */}}
{{- define "reviewdog.params" -}}
- description: "git revision to checkout (branch, tag, sha, ref…)"
  name: revision
  type: string
  default: ""
- description: "Reporter type of reviewdog: `github-pr-review`, `gitlab-mr-commit`."
  name: reporter
  type: string
  default: "github-pr-review"
{{- end }}

{{/* init script for reviewdog */}}
{{- define "reviewdog.initscript" -}}
set_reviewdog_env() {
  # parse access token
  url=$(git remote -v | head -n 1 | awk '{print $2}')
  if [ "${url:0:4}" == "http" ]; then
    # origin	https://github.com/katanomi/builds (fetch)
    current_host=$(echo $url | sed 's/.*\/\/\([^\/]*\).*/\1/')
    projectRepo=$(echo $url | sed 's/.*\/\/[^\/]*\/\([^\/]*\)\/\([^\/|\.]*\).*/\1:\2/')
  else
    # origin  git@github.com:nanjingfm/ulmaceae.git (fetch)
    # origin  ssh://git@github.com/nanjingfm/ulmaceae.git (fetch)
    current_host=$(echo $url | sed 's/.*@\([^\/:]*\)[\/|:].*/\1/')
    projectRepo=$(echo $url | sed 's/.*@[^\/:]*[\/:]\([^\/]*\)\/\([^\.]*\).*/\1:\2/')
  fi
  token=$(cat $HOME/.git-credentials |
    grep ${current_host} |
    sed 's/^.*:\/\/[^:]*:\([^@]*\)@.*$/\1/g')

  # parse pr num
  revision="$(params.revision)"
  PRNumber=$(echo "$revision" | grep -E '[0-9]+' -o)

  # parse repo info
  PROJECT=$(echo $projectRepo | awk -F: '{print $1}')
  REPO=$(echo $projectRepo | awk -F: '{print $2}')
  SHA="$(git rev-parse HEAD)"

  # set env
  export CI_REPO_NAME=$REPO
  export CI_REPO_OWNER=$PROJECT
  export CI_COMMIT=$SHA
  export CI_PULL_REQUEST=$PRNumber
  export REVIEWDOG_GITHUB_API_TOKEN=$token
  export REVIEWDOG_GITLAB_API_TOKEN=$token
  export REVIEWDOG_TOKEN=$token
}
echo 'Set the environment variables required by reviewdog ...'
set_reviewdog_env
{{- end }}
