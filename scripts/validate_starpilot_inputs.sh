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
[[ "$version" == "19.6.15" || "$version" == 19.6.15-* ]]
expect_hash userspace/usr/comma/setup c5df17f88cb4955eba4102f6791bc4fd7eb32474cb48e598e4e981c3e1d66893
expect_hash userspace/usr/comma/installer 370d154aaf7e1e9ee433c069348ae885036a9d8cc4c8babfbfae12c8d5b3f2e8

for path in \
  userspace/files/bluealsa.service \
  userspace/files/bluetooth-main.conf \
  userspace/files/starpilot-bluetooth-radio.service \
  userspace/files/starpilot-bluetooth.conf \
  userspace/usr/comma/bluetooth-enabled \
  userspace/usr/comma/bluetooth-radio; do
  [[ -f "$DIR/$path" ]]
done

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
[[ "$kernel_ref" == "a8e70870a66cb4bb6d380b182d7b5681624b7890" ]]

echo "StarPilot AGNOS inputs validated (19.6.15, C3/Bluetooth, factory installer)."
