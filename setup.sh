#!/bin/bash

if [ ! -f "setup_complete" ]; then

    echo "Updating packages..."
    sudo apt-get update
    sudo apt-get -y upgrade
    sudo apt-get -y install tmux build-essential gcc g++ make binutils software-properties-common libsnappy-dev unzip \
        python python-dev python-pip python-virtualenv \
        python3 python3-dev python3-pip python3-venv

    echo "Installing CUDA..."
    sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
    wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.0.176-1_amd64.deb
    wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/nvidia-machine-learning-repo-ubuntu1604_1.0.0-1_amd64.deb
    sudo dpkg -i ./cuda-repo-ubuntu1604_9.0.176-1_amd64.deb
    sudo dpkg -i ./nvidia-machine-learning-repo-ubuntu1604_1.0.0-1_amd64.deb
    sudo apt-get update
    sudo apt-get -y install cuda-9-0 cuda-cublas-9-0 cuda-cufft-9-0 cuda-curand-9-0 cuda-cusolver-9-0 cuda-cusparse-9-0 \
        libcudnn7=7.2.1.38-1+cuda9.0 libnccl2=2.2.13-1+cuda9.0 cuda-command-line-tools-9-0
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64
    sudo modprobe nvidia
    nvidia-smi

    echo "Creating new user for Python/Jupyter..."
    JUPYTER_PW=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/jupyter-pw" -H "Metadata-Flavor: Google")
    sudo useradd -m jupyter -p $(openssl passwd -crypt $JUPYTER_PW)

    echo "Installing and configuring Jupyter Lab..."
    pip3 install jupyterlab
    jupyter lab --generate-config --config /home/jupyter/.jupyter/jupyter_notebook_config.py
    JUPYTER_PW_HASH=$(python3 -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PW'))")
    echo "c.NotebookApp.password = u'"$JUPYTER_PW_HASH"'
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.token = u''
c.NotebookApp.notebook_dir = '/home/jupyter/'
c.NotebookApp.open_browser = False" >> /home/jupyter/.jupyter/jupyter_notebook_config.py

    echo "Some miscellaneous setup..."
    sudo chown -R jupyter /home/jupyter
    rm -f /etc/boto.cfg

    echo "Record setup completion..."
    touch "setup_complete"

fi

echo "Starting Jupyter Notebook..."
export HOME=/home/jupyter
sudo -u jupyter bash -c 'JUPYTER_RUNTIME_DIR=/home/jupyter/.jupyter/ JUPYTER_CONFIG_DIR=/home/jupyter/.jupyter/ jupyter lab' &

echo "Done!"
