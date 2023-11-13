## Description
Deploy image to Google Kubernetes Engine cluster by directly changing it's version.
Drawback is the lack of image deployment history, besides github actions history.

## Requirements
1. [Create GKE cluster](????????????????)
2. [Create service account key](https://developers.google.com/workspace/guides/ceate-credentials#:~:text=your%20service%20account%3A-,In%20the%20Google%20Cloud%20console%2C%20go%20to%20Menu%20menu,IAM%20%26%20Admin%20%3E%20Service%20Accounts.&text=Select%20your%20service%20account.,Add%20key%20%3E%20Create%20new%20key.)
3. [Grant access to update GKE resources](????????????)

## Action parameters
Name                              | Required  | Default value | Description
:---------------------------------|:---------:|:-------------:|:-----------
google_project_id                 | Y         |               | Google project ID of your project where GKE is created
google_kubernetes_cluster_name    | Y         |               | Google Kubernetes Cluster name
google_kubernetes_cluster_zone    | Y         |               | Google Kubernetes Cluster zone
service_account_key               | Y         |               | Base64 version of Google Cloud Platform service key to access Artifact Registry
application_name                  | Y         |               | Application name to update
container_name                    | Y         |               | Container name to update
image_repo_url                    | Y         |               | URL docker image repository where image is stored
image_name                        | Y         |               | Name of deployed image
image_tag                         | Y         |               | Tag of deployed image
namespace                         | Y         |               | Destination namespace where image should be updated
*type*                            | *N*       | *deployment*  | Type of updated resource (deployment/statefulset/daemonset) - deployment is default
*annotations*                     | *N*       |               | list of annotations separated by semicolon (example: *update_date: 20231029_181921, description_tag: Updated by GitHub Actions*)
*labels*                          | *N*       |               | list of labels separated by semicolon (example: *label1: value1, label2: value2*)
*init_containers*                 | *N*       |               | Name of init_containers to update with the same image_name:image_tag (list separated by semicolon, example: *init_container1, init_container2*)

## Example usage
```
- name: Google Artifact Registry Build & Push
  uses: piotrkrusinski/action-google-kubernetes-engine-deployment@[version tag]
  with:
    google_project_id: [gke_project_id]
    google_kubernetes_cluster_name: [gke_region]
    google_kubernetes_cluster_zone: [gke_zone]
    service_account_key: [base64 of service key]
    image_name: [image name]
    image_tag: [image_tag]
    namespace: [destination_namespace]
    type: [one_of_the_following: deployment/statefulset/daemonset]
```