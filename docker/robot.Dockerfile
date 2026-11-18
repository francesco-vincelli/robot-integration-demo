FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy
ENV TURTLEBOT3_MODEL=burger

SHELL ["/bin/bash", "-c"]

# Basic utilities + ROS utilities required by the demo
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-jazzy-ros-base \
        ros-jazzy-demo-nodes-cpp \
        ros-jazzy-demo-nodes-py \
        ros-jazzy-ros-gz \
        ros-jazzy-turtlebot3 \
        ros-jazzy-turtlebot3-msgs \
        ros-jazzy-turtlebot3-simulations \
        ros-jazzy-turtlebot3-teleop \
        bash \
        git \
        nano \
        curl \
        lsb-release \
        gnupg \
        iputils-ping \
        net-tools \
        mesa-utils \
        && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc

WORKDIR /workspace

CMD ["/bin/bash"]
