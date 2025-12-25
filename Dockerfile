# 使用 PyTorch 官方提供的开发镜像，包含 CUDA 11.3 和 PyTorch 1.10.0
# 虽然文档提及 CUDA 11.1，但 11.3 通常向后兼容且支持更广泛，MMCV 官方也有对应预编译包
FROM pytorch/pytorch:1.10.0-cuda11.3-cudnn8-devel

# 设置环境变量，避免交互式安装卡住，并指定 CUDA 架构
ENV DEBIAN_FRONTEND=noninteractive
ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0 7.5 8.0 8.6+PTX"
ENV TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
ENV FORCE_CUDA="1"

# 1. 安装系统基础依赖
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 git ninja-build libglib2.0-0 libxrender-dev \
    python3-dev libevent-dev build-essential wget vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Python 依赖库
# 注意：PyTorch 已经在基础镜像中安装了

# 安装 MMCV 系列 (使用对应 CUDA 11.3 和 PyTorch 1.10.0 的预编译包)
# 参考 doc/install.md 中的版本要求
RUN pip install mmcv-full==1.5.3 -f https://download.openmmlab.com/mmcv/dist/cu113/torch1.10.0/index.html
RUN pip install mmdet==2.25.1
RUN pip install mmsegmentation==0.25.0

# 安装其他项目依赖
# 注意：严格按照 doc/install.md 中的版本，如有冲突可能需要微调
RUN pip install \
    lyft_dataset_sdk \
    networkx==2.2 \
    numba==0.53.0 \
    numpy==1.23.5 \
    nuscenes-devkit \
    plyfile \
    scikit-image \
    tensorboard \
    trimesh==2.35.39 \
    setuptools==59.5.0 \
    yapf==0.40.1 \
    pycuda

# 3. 安装 mmdetection3d (特定版本 v1.0.0rc4)
WORKDIR /opt
RUN git clone https://github.com/open-mmlab/mmdetection3d.git
WORKDIR /opt/mmdetection3d
RUN git checkout v1.0.0rc4
RUN pip install -v -e .

# 4. 准备 FlashOcc 环境
# 将当前目录（FlashOcc 代码）复制到镜像中
WORKDIR /workspace/FlashOcc
COPY . /workspace/FlashOcc

# 安装 FlashOcc 项目依赖 (编译 projects/mmdet3d_plugin/ops 下的 CUDA 算子)
WORKDIR /workspace/FlashOcc/projects
RUN pip install -v -e .

# 5. 设置工作目录和默认命令
WORKDIR /workspace/FlashOcc
CMD ["/bin/bash"]
