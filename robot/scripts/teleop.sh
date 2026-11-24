#!/usr/bin/env bash

set -euo pipefail

source /opt/ros/jazzy/setup.bash

export TURTLEBOT3_MODEL=waffle

# turtlebot3_teleop 2.3.7 selects Twist only when ROS_DISTRO=humble.
# The custom warehouse and Nav2 bridge require geometry_msgs/msg/Twist.
ROS_DISTRO=humble \
ros2 run turtlebot3_teleop teleop_keyboard
