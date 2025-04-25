# Use an Ubuntu 22.04 base image with CUDA 12.6 support
FROM nvidia/cuda:12.6.2-base-ubuntu22.04

# Install dependencies and Python 3.10
RUN apt-get update && apt-get install -y \
    software-properties-common \
    build-essential \
    bash \
    sudo \
    git \
    curl \
    sed \
    libgoogle-perftools-dev \
    python3.10-venv \
    libgl1-mesa-glx \
    python3-pip

# Install Python packages
RUN python3.10 -m pip install --upgrade pip
RUN python3.10 -m pip install torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --extra-index-url https://download.pytorch.org/whl/cu121

# Create a non-root user and set a password as "default"
RUN useradd -ms /bin/bash appuser && \
    echo "appuser:default" | chpasswd

# Create a symlink for python3.10 as python
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Set working directory
WORKDIR /app

# Get latest automatic1111 release
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /app

# Modify the webui-user.sh file to add COMMANDLINE_ARGS
RUN sed -i 's|#export COMMANDLINE_ARGS=""|export COMMANDLINE_ARGS="--listen --medvram --xformers --enable-insecure-extension-access --api --allow-code --administrator"|' /app/webui-user.sh

# Grant sudo privileges to appuser
RUN echo "appuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/appuser

# Ensure webui.sh is executable as root
RUN chmod +x /app/webui.sh

# Change ownership of the application files to the non-root user
RUN chown -R appuser:appuser /app

# Set the PATH for appuser to include Python binaries
RUN echo "export PATH=/usr/bin/python3.10:/usr/local/bin:$PATH" >> /home/appuser/.bashrc

# Switch to the non-root user
USER appuser

# Create outputs directory
RUN mkdir -p /app/outputs && chown -R appuser:appuser /app/outputs

# Set the default command to run your script
CMD ["bash", "webui.sh"]
