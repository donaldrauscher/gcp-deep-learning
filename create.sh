#!/bin/bash

JUPYTER_PW=${JUPYTER_PW:-password}
REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)

JUPYTER_RULE=$(gcloud compute firewall-rules list --filter "NAME=jupyter" --format "table(name)")
JUPYTER_STATIC=$(gcloud compute addresses list --filter "NAME=jupyter" --format "table(name)")

if [ -z "$JUPYTER_RULE" ]; then
    gcloud compute firewall-rules create "jupyter" \
        --action ALLOW \
        --rules tcp:8888 \
        --direction "INGRESS" \
        --priority "1000" \
        --network "default" \
        --source-ranges "0.0.0.0/0" \
        --target-tags "jupyter"
fi

if [ -z "$JUPYTER_STATIC" ]; then
    gcloud compute addresses create "jupyter" --region $REGION
fi

JUPYTER_ADDR=$(gcloud compute addresses describe "jupyter" --region $REGION --format "value(address)")

gcloud beta compute instances create "deep-learning" \
    --address "$JUPYTER_ADDR" \
    --machine-type "n1-standard-2" \
    --accelerator type=nvidia-tesla-p100,count=1 \
    --image-family "ubuntu-1604-lts" --image-project "ubuntu-os-cloud" \
    --boot-disk-size "50" --boot-disk-type "pd-ssd" \
    --maintenance-policy "TERMINATE" \
    --metadata setup-status="pending",startup-script="$(cat setup.sh)",jupyter-pw="$JUPYTER_PW" \
    --tags "jupyter" \
    --scopes "cloud-platform"

SETUP_STATUS=$(gcloud compute instances describe deep-learning --zone $ZONE | awk '/setup-status/{getline;print $2;}' | awk 'FNR==1 {print $1}')
while [ "$SETUP_STATUS" = "pending" ]; do
	echo $SETUP_STATUS
	sleep 5
	SETUP_STATUS=$(gcloud compute instances describe deep-learning --zone $ZONE | awk '/setup-status/{getline;print $2;}' | awk 'FNR==1 {print $1}')
done
echo $SETUP_STATUS
