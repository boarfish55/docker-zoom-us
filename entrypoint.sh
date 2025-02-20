#!/bin/bash

set -x
set -e

USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}

ZOOM_US_USER=zoom

install_zoom_us() {
  echo "Installing zoom-us-wrapper..."
  install -m 0755 /var/cache/zoom-us/zoom-us-wrapper /target/
  echo "Installing zoom-us..."
  ln -sf zoom-us-wrapper /target/zoom
}

uninstall_zoom_us() {
  echo "Uninstalling zoom-us-wrapper..."
  rm -rf /target/zoom-us-wrapper
  echo "Uninstalling zoom-us..."
  rm -rf /target/zoom
}

create_user() {
  # create group with USER_GID
  if ! getent group ${ZOOM_US_USER} >/dev/null; then
    groupadd -f -g ${USER_GID} ${ZOOM_US_USER} >/dev/null 2>&1
  fi

  # create user with USER_UID
  if ! getent passwd ${ZOOM_US_USER} >/dev/null; then
    adduser --disabled-login --uid ${USER_UID} --gid ${USER_GID} \
      --gecos 'ZoomUs' ${ZOOM_US_USER} >/dev/null 2>&1
  fi
  find /home/${ZOOM_US_USER} -xdev -exec chown ${ZOOM_US_USER}:${ZOOM_US_USER} {} \;
  adduser ${ZOOM_US_USER} sudo
  for grp in $ZOOM_USER_GROUPS; do
    [[ ! -z "$grp" ]] && adduser ${ZOOM_US_USER} $grp
  done
}

grant_access_to_video_devices() {
  for device in /dev/video*
  do
    if [[ -c $device ]]; then
      VIDEO_GID=$(stat -c %g $device)
      VIDEO_GROUP=$(stat -c %G $device)
      if [[ ${VIDEO_GROUP} == "UNKNOWN" ]]; then
        VIDEO_GROUP=zoomusvideo
        groupadd -g ${VIDEO_GID} ${VIDEO_GROUP}
      fi
      usermod -a -G ${VIDEO_GROUP} ${ZOOM_US_USER}
      break
    fi
  done
}

launch_zoom_us() {
  cd /home/${ZOOM_US_USER}
  exec sudo -HEu ${ZOOM_US_USER} PULSE_SERVER=/run/pulse/$(basename $ZOOM_PULSE_SOCKET) QT_GRAPHICSSYSTEM="native" xcompmgr -c -l0 -t0 -r0 -o.00 &
  # NOTE: While passing --no-sandbox _and_ $@ is a valiant effort, it seems
  # the ZoomLaunher doesn't process multiple args successfully and just aborts.
  # It's one or the other, but since newer version of the chrome-sandbox,
  # it seems we absolutely need --no-sandbox to properly run inside docker.
  # TBD...
  exec sudo -HEu ${ZOOM_US_USER} PULSE_SERVER=/run/pulse/$(basename $ZOOM_PULSE_SOCKET) QT_GRAPHICSSYSTEM="native" zoom --no-sandbox $@
}

case "$1" in
  install)
    install_zoom_us
    ;;
  uninstall)
    uninstall_zoom_us
    ;;
  zoom)
    create_user
    grant_access_to_video_devices
    shift
    echo "$1"
    launch_zoom_us $@
    ;;
  *)
    exec $@
    ;;
esac
