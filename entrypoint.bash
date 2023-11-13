#!/bin/bash
set -e

echo -e "[ACTION] Checking if required parameters are set"
if [ -z "$INPUT_GOOGLE_PROJECT_ID" ];               then echo -e "[ACTION] Requirements not met: GOOGLE_PROJECT_ID not set";              exit 1; fi
if [ -z "$INPUT_GOOGLE_KUBERNETES_CLUSTER_NAME" ];  then echo -e "[ACTION] Requirements not met: GOOGLE_KUBERNETES_CLUSTER_NAME not set"; exit 1; fi
if [ -z "$INPUT_GOOGLE_KUBERNETES_CLUSTER_ZONE" ];  then echo -e "[ACTION] Requirements not met: GOOGLE_KUBERNETES_CLUSTER_ZONE not set"; exit 1; fi
if [ -z "$INPUT_SERVICE_ACCOUNT_KEY" ];             then echo -e "[ACTION] Requirements not met: SERVICE_ACCOUNT_KEY not set";            exit 1; fi
if [ -z "$INPUT_APPLICATION_NAME" ];                then echo -e "[ACTION] Requirements not met: APPLICATION_NAME not set";               exit 1; fi
if [ -z "$INPUT_CONTAINER_NAME" ];                  then echo -e "[ACTION] Requirements not met: CONTAINER_NAME not set";                 exit 1; fi
if [ -z "$INPUT_IMAGE_REPO_URL" ];                  then echo -e "[ACTION] Requirements not met: IMAGE_REPO_URL not set";                 exit 1; fi
if [ -z "$INPUT_IMAGE_NAME" ];                      then echo -e "[ACTION] Requirements not met: IMAGE_NAME not set";                     exit 1; fi
if [ -z "$INPUT_IMAGE_TAG" ];                       then echo -e "[ACTION] Requirements not met: IMAGE_TAG not set";                      exit 1; fi
if [ -z "$INPUT_NAMESPACE" ];                       then echo -e "[ACTION] Requirements not met: NAMESPACE not set";                      exit 1; fi


# lets decode SA key and save it locally in key file
echo -e "[ACTION] Preparing key used for authentication"
echo "$INPUT_SERVICE_ACCOUNT_KEY" | base64 -d > "$HOME"/sa_key.json

# authenticate to google using key file
echo -e "[ACTION] Authenticating to gcloud"
gcloud auth activate-service-account --key-file="$HOME"/sa_key.json --project "$INPUT_GOOGLE_PROJECT_ID"

# configure docker with specific Artifact Registry
echo -e "[ACTION] Get kubernetes credentials"
gcloud container clusters get-credentials $INPUT_GOOGLE_KUBERNETES_CLUSTER_NAME --zone=$INPUT_GOOGLE_KUBERNETES_CLUSTER_ZONE --project $INPUT_GOOGLE_PROJECT_ID

# Setting up variables

echo -e "[ACTION] Prepare type of update"
case "${INPUT_TYPE,,}" in
  "statefulset") TYPE=statefulset ;;
  "daemonset") TYPE=daemonset ;;
  *) TYPE=deployment
esac
echo -e "[ACTION]   TYPE: ${TYPE}"

# decode annotations list if set
OLD_IFS=$IFS
IFS=','

echo -e "[ACTION] Preparing annotations list"
if [ -z "$INPUT_ANNOTATIONS" ]; then
  ANNOTATIONS=()
else
  read -r -a ANNOTATIONS <<< "$INPUT_ANNOTATIONS"
fi

echo -e "[ACTION]   ANNOTATIONS found ${#ANNOTATIONS[@]}"
for ANNOTATION in ${ANNOTATIONS[@]}; do
  echo -e "[ACTION]    ${ANNOTATION/ /}"
done

# decode labels list if set
echo -e "[ACTION] Preparing labels list"
if [ -z "$INPUT_LABELS" ]; then
  LABELS=()
else
  read -r -a LABELS <<< "$INPUT_LABELS"
fi

echo -e "[ACTION]   LABELS found ${#LABELS[@]}"
for LABEL in ${LABELS[@]}; do
  echo -e "[ACTION]    ${LABEL/ /}"
done

# decode init_containers
echo -e "[ACTION] Preparing init_container list"
if [ -z "$INPUT_INIT_CONTAINERS" ]; then
  INIT_CONTAINERS=""
else
  read -r -a INIT_CONTAINERS <<< "$INPUT_INIT_CONTAINERS"
fi

echo -e "[ACTION]   INIT_CONTAINERS found ${#INIT_CONTAINERS[@]}"
INIT_CONTAINER_COMMAND=""
for INIT_CONTAINER in ${INIT_CONTAINERS[@]}; do
  echo -e "[ACTION]     ${INIT_CONTAINER/ /}"
  INIT_CONTAINER_COMMAND="$INIT_CONTAINER_COMMAND$INIT_CONTAINER=$INPUT_IMAGE_REPO_URL/$INPUT_IMAGE_NAME:$INPUT_IMAGE_TAG "
done
echo -e "[ACTION]   INIT_CONTAINERS_COMMAND:"
echo -e "[ACTION]     ${INIT_CONTAINER_COMMAND}"

# update annotations
if (( ${#ANNOTATIONS[@]} > 0 )); then
echo -e "[ACTION] Update annotations for application $INPUT_APPLICATION_NAME at $INPUT_NAMESPACE"
  for annotation in ${ANNOTATIONS[@]}; do
    IFS=':' 
    read -r -a annotation_array <<< "${annotation/ /}"
    echo "[ACTION]   Adding/updating annotation: ${annotation_array[0]}=${annotation_array[1]/ /}"
    kubectl annotate -n $INPUT_NAMESPACE --overwrite $TYPE $INPUT_APPLICATION_NAME ${annotation_array[0]}="${annotation_array[1]/ /}"
  done
fi

IFS=','
# update labels
if (( ${#LABELS[@]} > 0 )); then
  echo -e "[ACTION] found ${#LABELS[@]}"
  echo -e "[ACTION] Update labels for application $INPUT_APPLICATION_NAME at $INPUT_NAMESPACE"
  # OLD_IFS=$IFS
  for label in ${LABELS[@]}; do
    IFS=':' 
    read -r -a label_array <<< "${label/ /}"
    echo "[ACTION]   Adding/updating label: ${label_array[0]}=${label_array[1]/ /}"
    kubectl label -n $INPUT_NAMESPACE --overwrite $TYPE $INPUT_APPLICATION_NAME ${label_array[0]}="${label_array[1]/ /}"
  done
fi

IFS=$OLD_IFS

# update container image with init-containers
echo -e "[ACTION] Update application $INPUT_APPLICATION_NAME (container_name: $INPUT_CONTAINER_NAME), set image to $INPUT_IMAGE_REPO_URL/$INPUT_IMAGE_NAME:$INPUT_IMAGE_TAG at $INPUT_NAMESPACE"
kubectl set image --namespace=$INPUT_NAMESPACE $TYPE/$INPUT_APPLICATION_NAME $INPUT_CONTAINER_NAME=$INPUT_IMAGE_REPO_URL/$INPUT_IMAGE_NAME:$INPUT_IMAGE_TAG $INIT_CONTAINER_COMMAND 
