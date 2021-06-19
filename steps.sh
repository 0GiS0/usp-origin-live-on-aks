#Variables
RESOURCE_GROUP="usp-live-origin"
LOCATION="northeurope"
AKS_NAME="usp-live-origin-cluster"

#Create resource group
az group create -n $RESOURCE_GROUP -l $LOCATION

# Create AKS cluster
az aks create -n $AKS_NAME -g $RESOURCE_GROUP --node-count 1 --generate-ssh-keys

#Get the context for the new AKS
az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP

#Get the node resource group
NODE_RESOURCE_GROUP=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query nodeResourceGroup -o tsv)

#Create an Azure Disk in the node resource group
az disk create -g $NODE_RESOURCE_GROUP -n live-origin-assets --size-gb 500 --query id --output tsv
#The result, the disk URI, should be used to mount this volume in the Pod

#Create a secret with the USP Key
kubectl create secret generic live-origin-test-license-key --from-file=key

#Create the resources on AKS for USP live origin demo
kubectl apply -f .

#ffmpeg pushing a livestream to the Origin's publishing point using https://github.com/unifiedstreaming/live-demo-cmaf

kubectl exec live-origin-test-0 -- ls /var/www/live/test

#Get service public IP
kubectl get svc live-origin-test-0

#State of the publishing endpoint
curl http://<AKS_SERVICE_PUBLIC_IP>/test/test.isml/state

#Stadistics
curl http://<AKS_SERVICE_PUBLIC_IP>/test/test.isml/statistics

#Archive
curl http://<AKS_SERVICE_PUBLIC_IP>/test/test.isml/archive


#Testing the livestream

#Request a manifest for your live stream
curl -v http://<AKS_SERVICE_PUBLIC_IP>/test/test.isml/.mpd

#Tested with ffplay

#MPEG-DASH
ffplay http://<AKS_SERVICE_PUBLIC_IP>:80/test/test.isml/.mpd

#Apple's HLS
ffplay http://<AKS_SERVICE_PUBLIC_IP>:80/test/test.isml/.m3u8

#Microsoft's Smooth Streaming (not working)
http://reference.dashif.org/dash.js/v3.2.2/samples/dash-if-reference-player/index.html?url=http://<AKS_SERVICE_PUBLIC_IP>/test/test.isml/Manifest

#Adobe's Dynamic Streaming (hard to test)
http://<AKS_SERVICE_PUBLIC_IP>:80/test/test.isml/.f4m

