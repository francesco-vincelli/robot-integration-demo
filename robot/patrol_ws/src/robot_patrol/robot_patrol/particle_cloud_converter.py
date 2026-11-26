#!/usr/bin/env python3

import rclpy

from geometry_msgs.msg import PoseArray
from nav2_msgs.msg import ParticleCloud
from rclpy.node import Node
from rclpy.qos import (
    DurabilityPolicy,
    HistoryPolicy,
    QoSProfile,
    ReliabilityPolicy,
)


class ParticleCloudConverter(Node):
    """Convert Nav2 ParticleCloud messages into RViz-compatible PoseArray."""

    def __init__(self):
        super().__init__('particle_cloud_converter')

        self.declare_parameter(
            'input_topic',
            '/particle_cloud',
        )

        self.declare_parameter(
            'output_topic',
            '/particle_cloud_pose_array',
        )

        self.declare_parameter(
            'max_particles',
            0,
        )

        input_topic = self.get_parameter(
            'input_topic'
        ).get_parameter_value().string_value

        output_topic = self.get_parameter(
            'output_topic'
        ).get_parameter_value().string_value

        self.max_particles = self.get_parameter(
            'max_particles'
        ).get_parameter_value().integer_value

        particle_qos = QoSProfile(
            reliability=ReliabilityPolicy.BEST_EFFORT,
            durability=DurabilityPolicy.VOLATILE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10,
        )

        pose_array_qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            durability=DurabilityPolicy.VOLATILE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10,
        )

        self.publisher = self.create_publisher(
            PoseArray,
            output_topic,
            pose_array_qos,
        )

        self.subscription = self.create_subscription(
            ParticleCloud,
            input_topic,
            self.particle_cloud_callback,
            particle_qos,
        )

        self.get_logger().info(
            f'Converting {input_topic} to {output_topic}'
        )

        if self.max_particles > 0:
            self.get_logger().info(
                'RViz output limited to '
                f'{self.max_particles} particles'
            )

    def particle_cloud_callback(
        self,
        message: ParticleCloud,
    ) -> None:
        output = PoseArray()

        output.header = message.header

        particles = message.particles

        if (
            self.max_particles > 0
            and len(particles) > self.max_particles
        ):
            step = max(
                1,
                len(particles) // self.max_particles,
            )

            particles = particles[::step][
                :self.max_particles
            ]

        output.poses = [
            particle.pose
            for particle in particles
        ]

        self.publisher.publish(output)


def main(args=None):
    rclpy.init(args=args)

    node = ParticleCloudConverter()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()

        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
