#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAPTURE_DIR="${1:-$REPO_ROOT/artifacts/app-store-refresh-2026-09-29}"
OUTPUT_DIR="$REPO_ROOT/AppStoreAssets/ReleasePreviews/en-US"
mkdir -p "$OUTPUT_DIR"
render() {
  local prefix="$1" width="$2" height="$3" label="$4"
  local live_crop="" live_start="12"
  if [[ "$prefix" == "iphone" ]]; then
    live_crop="crop=iw:ih-120:0:120,"
    live_start="10"
  fi
  local output="$OUTPUT_DIR/NameSnap-AppPreview-$label-${width}x${height}.mp4"
  ffmpeg -y -i "$CAPTURE_DIR/$prefix-input.mov" -i "$CAPTURE_DIR/$prefix-live-draw.mov" \
    -i "$CAPTURE_DIR/$prefix-postdraw-reset.mov" \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -filter_complex "[0:v]tpad=stop_mode=clone:stop_duration=3,trim=duration=3,setpts=PTS-STARTPTS,fps=30,scale=$width:$height:flags=lanczos,setsar=1,format=yuv420p[a];[1:v]trim=start=$live_start,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=14,trim=duration=14,fps=30,${live_crop}scale=$width:$height:force_original_aspect_ratio=decrease:flags=lanczos,pad=$width:$height:(ow-iw)/2:(oh-ih)/2:color=0xf7f8fc,setsar=1,format=yuv420p[b];[2:v]tpad=stop_mode=clone:stop_duration=4,trim=duration=4,setpts=PTS-STARTPTS,fps=30,${live_crop}scale=$width:$height:force_original_aspect_ratio=decrease:flags=lanczos,pad=$width:$height:(ow-iw)/2:(oh-ih)/2:color=0xf7f8fc,setsar=1,format=yuv420p[c];[a][b][c]concat=n=3:v=1:a=0[v]" \
    -map '[v]' -map 3:a -t 21 -c:v libx264 -profile:v high -level:v 4.0 \
    -b:v 11M -minrate 11M -maxrate 11M -bufsize 22M -x264-params 'nal-hrd=cbr:force-cfr=1' \
    -pix_fmt yuv420p -r 30 -c:a aac -b:a 256k -ar 48000 -ac 2 -movflags +faststart "$output"
  ffmpeg -y -ss 15 -i "$output" -frames:v 1 -pix_fmt rgb24 "$OUTPUT_DIR/NameSnap-AppPreview-$prefix-Poster-15s.png"
}
render iphone 886 1920 IPHONE_67
render ipad 1200 1600 IPAD_PRO_3GEN_129
