#!/bin/bash

gcloud beta compute instances delete "deep-learning"
gcloud compute firewall-rules delete "jupyter"
