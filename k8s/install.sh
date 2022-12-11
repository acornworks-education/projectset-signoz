#!/bin/bash

check_packages() {
    if ! [ -x "$(command -v kubectl)" ]; then
        echo "Kubectl is not installed ..."
        exit 1
    fi

    if ! [ -x "$(command -v helm)" ]; then
        echo "Helm is not installed ..."
        exit 1
    fi

    if ! [ -x "$(command -v jq)" ]; then
        echo "Jq is not installed ..."
        exit 1
    fi

    echo "All required packages are installed. It's good to go ahead ..."
}

set_default_storage() {
    echo "Try to patch a storage class to enable PVC resize ..."

    local DEFAULT_STORAGE_CLASS=$(kubectl get storageclass -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
    kubectl patch storageclass "$DEFAULT_STORAGE_CLASS" -p '{"allowVolumeExpansion": true}'
}

install_signoz() {
    local repo_url="https://charts.signoz.io"
    local repo_name=signoz
    local target_namespace=signoz
    local svc_exist=""
    local available_replicas=0

    local check_installed=$(helm repo list -o json | jq -c ".[] | select(.url | contains(\"$repo_url\"))")

    if [ -z "$check_installed" ]
    then
        echo "Try to install a Helm repository ..."
        helm repo add $repo_name $repo_url
    else
        echo "Helm repository is already added ..."
        repo_name=$(echo $check_installed | jq -r .name)
    fi

    local check_namespace=$(kubectl get ns -o json | jq -c ".items[] | select(.metadata.name | contains(\"$target_namespace\"))")

    if [ -z "$check_namespace" ]
    then
        kubectl create ns $target_namespace
    else
        echo "$target_namespace namespace already exists ..."
    fi
    
    helm --namespace $target_namespace install default $repo_name/signoz

    while [ -z "$svc_exist" ]
    do
        sleep 5
        svc_exist=$(kubectl get svc -n signoz -o json | jq -c ".items[] | select(.metadata.name | contains(\"default-signoz-frontend\"))")
    done

    kubectl patch svc default-signoz-frontend -n $target_namespace -p '{"spec": {"type": "LoadBalancer"}}'

    while [ $available_replicas -eq 0 ]
    do
        echo "Try to wait 10 seconds to run a Signoz frontend ..."
        sleep 10
        available_replicas=$(kubectl get deploy -n signoz default-signoz-frontend -o json | jq -c ".status.availableReplicas")
    done
}

check_packages
set_default_storage
install_signoz
