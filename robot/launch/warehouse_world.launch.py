from pathlib import Path
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource


def generate_launch_description():
    world = Path('/workspace/robot/worlds/warehouse_demo.sdf')
    gz_launch = Path(get_package_share_directory('ros_gz_sim')) / 'launch' / 'gz_sim.launch.py'
    return LaunchDescription([
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(str(gz_launch)),
            launch_arguments={'gz_args': f'-r -v 3 {world}'}.items(),
        )
    ])
