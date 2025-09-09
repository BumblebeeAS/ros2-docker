# Dockerfiles

`isaac_ros_jp6` contains Dockerfiles specific to Nvidia's JetPack 6 for Jetson and `isaac_ros_x64` contains Dockerfiles for normal `x64` computers. `common` contains Dockerfiles usable by both types of systems.

Side note: the reason why vehicle specific files are in `common` is because we use them on both JetPack 6 devices (the Jetsons themselves) and our personal laptops (which have x64 architecture).
