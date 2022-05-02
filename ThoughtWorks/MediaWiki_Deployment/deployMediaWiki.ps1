[cmdletbinding()]
# param(
#     [parameter(Mandatory)] $DockerUserName,
#     [parameter(Mandatory)] $DockerPassword
#      )
#$ErrorActionPreference = "Stop"
$SUBSCRIPTION = "<subscription-id"
$RESOURCEGROUP = "<resource-group-name>"
$CLUSTERNAME = "<cluster-name>"
$MediaWikiNameSpace   = "wiki"

Push-Location $PSScriptRoot

write-host "--------------------------------------------------------------"
write-host "SET SUBSCRIPTION"
write-host "--------------------------------------------------------------"
az account set --subscription $SUBSCRIPTION
Write-Host "Subscription set to $SUBSCRIPTION"

write-host "--------------------------------------------------------------"
write-host "GET $CLUSTERNAME CREDENTIALS"
write-host "--------------------------------------------------------------"
az aks get-credentials --resource-group $RESOURCEGROUP --name $CLUSTERNAME

#Set cluster
kubectl config use-context $CLUSTERNAME

write-host "--------------------------------------------------------------"
write-host "CREATE $MediaWikiNameSpace  NAMESPACE"
write-host "--------------------------------------------------------------"
$NameSpace=$(kubectl get namespace $MediaWikiNameSpace  --ignore-not-found)

if ($NameSpace) {
    Write-Host "Skipping creation of $MediaWikiNameSpace  - already exists"
} else {
    kubectl create namespace $MediaWikiNameSpace 
    Write-Host "namespace $NameSpace  created"
}

# write-host "--------------------------------------------------------------"
# write-host "CREATE REGISTRY SECRET"
# write-host "--------------------------------------------------------------"
# $secret = kubectl get secret $secretName -n $MediaWikiNameSpace --ignore-not-found

# if ($secret) {
#     Write-Host "$secretName secret already exists, skipping secret creation"
# } else {
#     kubectl create secret docker-registry $secretName --docker-server=<registry-name> --docker-username=$DockerUserName --docker-password=$DockerPassword --docker-email=$DockerUserName -n $MediaWikiNameSpace 
# }

write-host "--------------------------------------------------------------"
write-host "Add Bitnami MediaWiki Helm Chart Repository"
write-host "--------------------------------------------------------------"

helm repo add bitnami https://charts.bitnami.com/bitnami

write-host "--------------------------------------------------------------"
write-host "Update Helm Repository"
write-host "--------------------------------------------------------------"

helm repo update

write-host "--------------------------------------------------------------"
write-host "Apply Bitnami MediaWiki Helm Chart Repository"
write-host "--------------------------------------------------------------"

helm install mediawiki -n wiki bitnami/mediawiki

write-host "--------------------------------------------------------------"
write-host "Getting Deployment Values"
write-host "--------------------------------------------------------------"

$APP_HOST=$(kubectl get svc --namespace wiki mediawiki --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo "Application Host: $APP_HOST"

$APP_PASSWORD= $([Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($(kubectl get secret --namespace wiki mediawiki -o jsonpath="{.data.mediawiki-password}"))))
echo "Application Password: $APP_PASSWORD"

$MARIADB_ROOT_PASSWORD=$([Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($(kubectl get secret --namespace wiki mediawiki-mariadb -o jsonpath="{.data.mariadb-root-password}"))))
echo "MariaDb Root Password: $MARIADB_ROOT_PASSWORD"

$MARIADB_PASSWORD=$([Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($(kubectl get secret --namespace wiki mediawiki-mariadb -o jsonpath="{.data.mariadb-password}"))))
echo "MariaDb Password: $MARIADB_PASSWORD"

write-host "--------------------------------------------------------------"
write-host "Upgrade Helm Deployment"
write-host "--------------------------------------------------------------"
helm upgrade --namespace wiki mediawiki bitnami/mediawiki --set mediawikiHost=$APP_HOST,mediawikiPassword=$APP_PASSWORD,mariadb.auth.rootPassword=$MARIADB_ROOT_PASSWORD,mariadb.auth.password=$MARIADB_PASSWORD

write-host "--------------------------------------------------------------"
write-host "Please use following credentials to login"
write-host "--------------------------------------------------------------"

$SERVICE_IP=$(kubectl get svc --namespace wiki mediawiki --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

echo "Mediawiki URL: http://$SERVICE_IP/"
echo Username: user
echo Password: $([Text.Encoding]::Utf8.GetString([Convert]::FromBase64String( $(kubectl get secret --namespace wiki mediawiki -o jsonpath="{.data.mediawiki-password}"))))


