#!/usr/bin/env python3

from pathlib import Path

from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch.actions import (
    AppendEnvironmentVariable,
    DeclareLaunchArgument,
    ExecuteProcess,
)
from launch.substitutions import LaunchConfiguration
from launch.substitutions.command import Command
from launch.substitutions.find_executable import FindExecutable

from launch_ros.actions import Node


ROBOT_ROOT = Path('/workspace/robot')

WORLD_FILE = (
    ROBOT_ROOT
    / 'worlds'
    / 'warehouse_demo.sdf'
)

GUI_CONFIG = (
    ROBOT_ROOT
    / 'config'
    / 'warehouse_gui.config'
)

ROBOT_SDF = (
    ROBOT_ROOT
    / 'models'
    / 'turtlebot3'
    / 'gz_waffle.sdf.xacro'
)

# Repository-owned URDF with corrected package mesh paths.
ROBOT_URDF = (
    ROBOT_ROOT
    / 'models'
    / 'turtlebot3'
    / 'turtlebot3_waffle.urdf'
)

BRIDGE_CONFIG = (
    ROBOT_ROOT
    / 'config'
    / 'turtlebot3_waffle_bridge.yaml'
)


def generate_launch_description():
    namespace = LaunchConfiguration('namespace')
    robot_name = LaunchConfiguration('robot_name')

    x_pose = LaunchConfiguration('x_pose')
    y_pose = LaunchConfiguration('y_pose')
    z_pose = LaunchConfiguration('z_pose')

    roll = LaunchConfiguration('roll')
    pitch = LaunchConfiguration('pitch')
    yaw = LaunchConfiguration('yaw')

    minimal_tb3_share = Path(
        get_package_share_directory('nav2_minimal_tb3_sim')
    )

    # Gazebo needs the installed package resources because the Waffle
    # SDF refers to package-provided meshes and models.
    resource_paths = [
        str(minimal_tb3_share / 'models'),
        str(minimal_tb3_share.parent),
        str(ROBOT_ROOT / 'models'),
        str(ROBOT_ROOT / 'worlds'),
    ]

    declare_namespace = DeclareLaunchArgument(
        'namespace',
        default_value='',
        description='Top-level ROS namespace',
    )

    declare_robot_name = DeclareLaunchArgument(
        'robot_name',
        default_value='turtlebot3_waffle',
        description='Gazebo entity name',
    )

    # Home zone, facing approximately east into the warehouse.
    declare_x_pose = DeclareLaunchArgument(
        'x_pose',
        default_value='-4.35', #'-4.75',
        description='Initial robot X position in metres',
    )

    declare_y_pose = DeclareLaunchArgument(
        'y_pose',
        default_value='2.85', # '3.20',
        description='Initial robot Y position in metres',
    )

    declare_z_pose = DeclareLaunchArgument(
        'z_pose',
        default_value='0.10',
        description='Initial robot Z position in metres',
    )

    declare_roll = DeclareLaunchArgument(
        'roll',
        default_value='0.0',
        description='Initial robot roll in radians',
    )

    declare_pitch = DeclareLaunchArgument(
        'pitch',
        default_value='0.0',
        description='Initial robot pitch in radians',
    )

    declare_yaw = DeclareLaunchArgument(
        'yaw',
        default_value='0.0',
        description='Initial robot yaw in radians',
    )

    gazebo = ExecuteProcess(
        cmd=[
            'gz',
            'sim',
            '-r',
            '-v',
            '3',
            '--gui-config',
            str(GUI_CONFIG),
            str(WORLD_FILE),
        ],
        output='screen',
    )

    gazebo_robot_description = Command([
        FindExecutable(name='xacro'),
        ' ',
        str(ROBOT_SDF),
        ' ',
        'namespace:=',
        namespace,
    ])

    spawn_robot = Node(
        package='ros_gz_sim',
        executable='create',
        namespace=namespace,
        output='screen',
        arguments=[
            '-name',
            robot_name,
            '-string',
            gazebo_robot_description,
            '-x',
            x_pose,
            '-y',
            y_pose,
            '-z',
            z_pose,
            '-R',
            roll,
            '-P',
            pitch,
            '-Y',
            yaw,
        ],
    )

    bridge = Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        namespace=namespace,
        output='screen',
        parameters=[{
            'config_file': str(BRIDGE_CONFIG),
            'expand_gz_topic_names': True,
            'use_sim_time': True,
        }],
    )

    # RViz and robot_state_publisher use the corrected repository URDF.
    urdf_text = ROBOT_URDF.read_text(encoding='utf-8')

    robot_state_publisher = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        namespace=namespace,
        output='screen',
        parameters=[{
            'robot_description': urdf_text,
            'use_sim_time': True,
        }],
        remappings=[
            ('/tf', 'tf'),
            ('/tf_static', 'tf_static'),
        ],
    )

    actions = [
        declare_namespace,
        declare_robot_name,
        declare_x_pose,
        declare_y_pose,
        declare_z_pose,
        declare_roll,
        declare_pitch,
        declare_yaw,
    ]

    for resource_path in resource_paths:
        actions.append(
            AppendEnvironmentVariable(
                'GZ_SIM_RESOURCE_PATH',
                resource_path,
            )
        )

    actions.extend([
        gazebo,
        bridge,
        robot_state_publisher,
        spawn_robot,
    ])

    return LaunchDescription(actions)
