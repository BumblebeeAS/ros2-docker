"""Exercise the metadata initialization that crashed in the ARM64 wheel."""

import asyncio
import socket

import rclpy  # Also check that the replacement works with ROS libraries loaded.
from mavsdk.asyncio import ComponentType, Configuration, Mavsdk

# MAVLink v1 HEARTBEAT: system/component 1, quadrotor, PX4, standby, valid CRC.
HEARTBEAT = bytes.fromhex("fe090001010000000000020c00030329f2")


async def send_heartbeats():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        while True:
            sock.sendto(HEARTBEAT, ("127.0.0.1", 19040))
            await asyncio.sleep(0.2)


async def main():
    sdk = Mavsdk(
        Configuration.create_with_component_type(ComponentType.COMPANION_COMPUTER)
    )
    try:
        await sdk.add_any_connection("udpin://127.0.0.1:19040")
        async with asyncio.TaskGroup() as tasks:
            sender = tasks.create_task(send_heartbeats())
            drone = await sdk.first_autopilot(5)
            assert drone is not None and await drone.is_connected()
            sender.cancel()
        print("Native MAVSDK discovery passed")
    finally:
        sdk.destroy()


if __name__ == "__main__":
    asyncio.run(main())
