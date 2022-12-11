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

    echo "All required packages are installed. It's good to go ahead ..."
}

uninstall_signoz() {
    local target_namespace=signoz

    helm --namespace $target_namespace uninstall default

    kubectl delete -n $target_namespace --all svc
    kubectl delete -n $target_namespace --all statefulset
    kubectl delete -n $target_namespace --all pods
    kubectl delete ns $target_namespace
}

check_packages
uninstall_signoz
