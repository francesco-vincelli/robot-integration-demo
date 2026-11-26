FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy
SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-jazzy-ros-base \
        python3 \
        bash \
        procps \
        iputils-ping \
        net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc
WORKDIR /workspace
CMD ["/bin/bash"]
