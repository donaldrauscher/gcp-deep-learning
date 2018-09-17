#!/bin/bash

echo "Updating packages..."
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install tmux build-essential gcc g++ make binutils software-properties-common \
    python python-dev python-pip

echo "Checking for CUDA and installing..."
if ! dpkg-query -W cuda-8-0; then
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.44-1_amd64.deb
    sudo dpkg -i ./cuda-repo-ubuntu1604_8.0.44-1_amd64.deb
    sudo apt-get update
    sudo apt-get -y install cuda-8-0
    sudo modprobe nvidia
    nvidia-smi
fi

echo "Installing and configuring Jupyter Notebook..."
if [ ! -f "/root/.jupyter/jupyter_notebook_config.py" ]; then
    pip install jupyter
    jupyter notebook --generate-config
    JUPYTER_PW=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/jupyter-pw" -H "Metadata-Flavor: Google")
    JUPYTER_PW_HASH=$(python -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PW'))")
    echo "c.NotebookApp.password = u'"$JUPYTER_PW_HASH"'
c.NotebookApp.ip = '*'
c.NotebookApp.token = u''
c.NotebookApp.allow_root = True
c.NotebookApp.open_browser = False" >> /root/.jupyter/jupyter_notebook_config.py
fi

echo "Starting Jupyter Notebook..."
jupyter notebook --port=8888
