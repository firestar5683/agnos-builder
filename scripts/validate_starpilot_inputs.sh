#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

expect_hash() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(sha256 "$DIR/$path")"
  if [[ "$actual" != "$expected" ]]; then
    echo "starpilot input hash mismatch: $path" >&2
    echo "expected: $expected" >&2
    echo "actual:   $actual" >&2
    exit 1
  fi
}

version="$(tr -d '\n' < "$DIR/VERSION")"
[[ "$version" == "19.6.20" || "$version" == 19.6.20-* ]]
expect_hash userspace/usr/comma/setup c5df17f88cb4955eba4102f6791bc4fd7eb32474cb48e598e4e981c3e1d66893
expect_hash userspace/usr/comma/installer 370d154aaf7e1e9ee433c069348ae885036a9d8cc4c8babfbfae12c8d5b3f2e8
expect_hash userspace/files/amdgpu/gc_12_0_0_imu.bin.zst 1b095036d45d4280a72976ffdc5fa015fb33d528c87da688dd290bbb9716084f
expect_hash userspace/files/amdgpu/gc_12_0_0_me.bin.zst 0bf7d4b54ace8af59d5c99c289bbb1b8ce77d11114bb880df308be2c9d5e2638
expect_hash userspace/files/amdgpu/gc_12_0_0_mec.bin.zst b19544dc8138123d29d25b79116fc4354dd465640408f86c08a4c7ad6b1d32d4
expect_hash userspace/files/amdgpu/gc_12_0_0_pfp.bin.zst 06b2ba632fa1878a16b78d9734dc8211020d257c140202462f764a156e98daef
expect_hash userspace/files/amdgpu/gc_12_0_0_rlc.bin.zst de1720ca1c7d062794e6c40627e49b2b1ea1a2a2e29c37db9a98bde5129fa762
expect_hash userspace/files/amdgpu/psp_14_0_2_sos.bin.zst d6bc2e002a02873d9060bdd48b231a4738eefbc0636c1593d4c1d24ce6916f83
expect_hash userspace/files/amdgpu/sdma_7_0_0.bin.zst 761015341774f11e4f5384e1d3c2da0a53b3d2e5926f0f8fdf7611280c06fcbc
expect_hash userspace/files/amdgpu/smu_14_0_2.bin.zst b0a03edf1c7e5a171fafe0710165b6ce90540450d1cf00132d8f0033b6ad2099
expect_hash userspace/webrtc/patches/libdatachannel-build.patch 22bce5ba596589b3333ef7812ca9185a67ef3d772bfa2e90b8e2f411b105b525
expect_hash userspace/webrtc/patches/libjuice-zero-tiebreaker.patch 37273f1a52757b491a29af6652731504a135f4e3f672daa69846f04292d38958

for path in \
  userspace/files/bluealsa.service \
  userspace/files/bluetooth-main.conf \
  userspace/files/starpilot-bluetooth-radio.service \
  userspace/files/starpilot-bluetooth.conf \
  userspace/usr/comma/bluetooth-enabled \
  userspace/usr/comma/bluetooth-radio \
  userspace/webrtc/build_libdatachannel.sh \
  userspace/webrtc/check_ice.py; do
  [[ -f "$DIR/$path" ]]
done

grep -Fxq 'HandlePowerKey=ignore' "$DIR/userspace/files/logind.conf"
grep -Fxq 'HandlePowerKeyLongPress=ignore' "$DIR/userspace/files/logind.conf"
grep -Fxq 'ExecStop=/usr/comma/bluetooth-radio stop' "$DIR/userspace/files/starpilot-bluetooth-radio.service"
grep -Fxq 'ExecStopPost=/usr/comma/bluetooth-radio cleanup' "$DIR/userspace/files/starpilot-bluetooth-radio.service"
grep -Fxq 'Restart=on-failure' "$DIR/userspace/files/starpilot-bluetooth-radio.service"
grep -Fxq 'systemctl disable bluealsa-aplay.service' "$DIR/userspace/services.sh"
grep -Fxq 'SOURCE_REV="989d29a32968046a002b5b9deb7a00f5012c530c"' "$DIR/userspace/webrtc/build_libdatachannel.sh"
grep -Fxq 'RUN bash /tmp/agnos/webrtc/build_libdatachannel.sh /tmp/webrtc-wheels /usr/local/venv/bin/python' "$DIR/Dockerfile.agnos"
grep -Fxq 'COPY --from=agnos-compiler-webrtc /tmp/webrtc-wheels /tmp/agnos/webrtc-wheels' "$DIR/Dockerfile.agnos"
grep -Fxq '    $XDG_DATA_HOME/venv/bin/python /usr/comma/tests/webrtc_ice_check.py' "$DIR/Dockerfile.agnos"

for dependency in \
  'crcmod==1.7' \
  'pyserial==3.5' \
  'kaitaistruct==0.11' \
  'aiohttp==3.12.15' \
  'json-rpc==1.15.0' \
  'mapbox-earcut==1.0.3' \
  'onnx==1.18.0' \
  'opencv-python-headless==4.11.0.86' \
  'pyaudio==0.2.14' \
  'xattr==1.2.0'; do
  grep -Fq "\"$dependency\"" "$DIR/userspace/uv/pyproject.toml"
done

if command -v uv >/dev/null 2>&1; then
  (cd "$DIR/userspace/uv" && uv lock --check)
fi

kernel_ref="$(git -C "$DIR/agnos-kernel-sdm845" rev-parse HEAD 2>/dev/null || true)"
[[ "$kernel_ref" == "4ee6b71b8ab9a461248985470726f5917943bc91" ]]

echo "StarPilot AGNOS inputs validated (19.6.20, C3/Bluetooth, factory installer, WebRTC ICE fix)."
