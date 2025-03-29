rosdep install --from-paths src --ignore-src -r -y # install dependencies

ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedm \
    publish_tf:=false
