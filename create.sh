#!/bin/bash

JUPYTER_PW=${JUPYTER_PW:-password}

gcloud compute firewall-rules create "jupyter" \
    --action ALLOW \
    --rules tcp:8888 \
    --direction "INGRESS" \
    --priority "1000" \
    --network "default" \
    --source-ranges "0.0.0.0/0" \
    --target-tags "jupyter"

gcloud beta compute instances create "deep-learning" \
    --machine-type "n1-standard-2" \
    --accelerator type=nvidia-tesla-p100,count=1 \
    --image-family "ubuntu-1604-lts" --image-project "ubuntu-os-cloud" \
    --boot-disk-size "50" --boot-disk-type "pd-ssd" \
    --maintenance-policy "TERMINATE" \
    --metadata startup-script="$(cat setup.sh)",jupyter-pw="$JUPYTER_PW" \
    --tags "jupyter"
