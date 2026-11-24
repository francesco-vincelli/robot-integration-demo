from pathlib import Path

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    package_share = Path(
        get_package_share_directory('robot_patrol')
    )

    parameters_file = package_share / 'config' / 'patrol.yaml'

    return LaunchDescription([
        Node(
            package='robot_patrol',
            executable='patrol_node',
            name='robot_patrol',
            output='screen',
            parameters=[str(parameters_file)],
        ),
    ])
