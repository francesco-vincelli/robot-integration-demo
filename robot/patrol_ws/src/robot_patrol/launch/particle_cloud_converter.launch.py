#!/usr/bin/env python3

from launch import LaunchDescription

from launch_ros.actions import Node


def generate_launch_description():
    converter = Node(
        package='robot_patrol',
        executable='particle_cloud_converter',
        name='particle_cloud_converter',
        output='screen',
        parameters=[{
            'input_topic': '/particle_cloud',
            'output_topic': '/particle_cloud_pose_array',

            # Use 0 to publish every AMCL particle.
            # Use 500 to reduce RViz rendering load if necessary.
            'max_particles': 0,
        }],
    )

    return LaunchDescription([
        converter,
    ])
