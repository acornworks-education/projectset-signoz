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
    kubectl delete ns $target_namespace &
    kubectl proxy &
    kubectl get namespace signoz -o json |jq '.spec = {"finalizers":[]}' >temp.json
    curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/signoz/finalize
}

check_packages
uninstall_signoz
