from glob import glob
from setuptools import find_packages, setup


package_name = 'robot_patrol'


setup(
    name=package_name,
    version='0.1.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        (
            'share/ament_index/resource_index/packages',
            ['resource/' + package_name],
        ),
        (
            'share/' + package_name,
            ['package.xml'],
        ),
        (
            'share/' + package_name + '/config',
            glob('config/*.yaml'),
        ),
        (
            'share/' + package_name + '/launch',
            glob('launch/*.launch.py'),
        ),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Francesco Vincelli',
    maintainer_email='francesco@example.com',
    description=(
        'Repeatable Nav2 waypoint patrol for the '
        'robot security integration demo.'
    ),
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'patrol_node = robot_patrol.patrol_node:main',
            'particle_cloud_converter = robot_patrol.particle_cloud_converter:main',
        ],
    },
)
