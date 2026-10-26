# UAV camera setup

Install the IMX219 ISP override on the Jetson host, from this repository root:

```bash
bash environments/uav/install-camera-isp.sh
```

Reboot to apply it. The installer backs up any existing override. Leave software color correction disabled until it is recalibrated with this ISP setting.
