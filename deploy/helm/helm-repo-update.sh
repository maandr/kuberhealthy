
# Modify Chart.yaml based on whether workflow was triggered by a new tag or a file update in ./deploy/helm
if [[ ${GITHUB_REF##*/} =~ "v"[0-9].*\.[0-9].*\.[0-9].* ]]; then
	sed -i -e "s/^appVersion:.*/appVersion: ${GITHUB_REF##*/}/" ./deploy/helm/kuberhealthy/Chart.yaml
	sed -i -e "s/^version:.*/version: $GITHUB_RUN_NUMBER/" ./deploy/helm/kuberhealthy/Chart.yaml
else
	sed -i -e "s/^version:.*/version: $GITHUB_RUN_NUMBER/" ./deploy/helm/kuberhealthy.Chart.yaml
fi

# The github action we use has helm 3 (required) as 'helmv3' in its path, so we alias that in and use it if present
HELM="helm"
if which helmv3; then
    echo "Using helm v3 alias"
    HELM="helmv3"
fi

$HELM version

# Lint helm chart
$HELM lint ./kuberhealthy
if [ "$?" -ne "0" ]; then
  echo "Linting reports error"
  exit 1
fi

# Package Helm Charts
$HELM package --version $GITHUB_RUN_NUMBER -d ../../helm-repos/tmp.d ./kuberhealthy

# Append new package info to top of helm index file
cd ../../helm-repos
$HELM repo index ./tmp.d --merge ./index.yaml --url https://comcast.github.io/kuberhealthy/helm-repos/archives

# Move the newly packaged .tgz file and index.yaml where they need to be
mv -f ./tmp.d/kuberhealthy-*.tgz ./archives
mv -f ./tmp.d/index.yaml ./
