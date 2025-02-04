base_path="drone_behaviors/behavior_trees/"
echo -n "Please enter the target behavior tree name (e.g. test_pub.xml): "
read -r target_tree_filename
target_tree="${base_path}${tree_filename}"
ros2 action send_goal /aaa/my_engine bb_behavior_msgs/action/Mission "{
    plugins: [bb, drone], 
    target_tree: '$target_tree', 
    tear_down_tree: '', 
    payload: '', 
    poses: []
}"