#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 OUTPUT_DIRECTORY" >&2
  exit 64
fi

for command_name in curl ffmpeg ffprobe; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 69
  fi
done

output_directory=$1
mkdir -p "$output_directory"

working_directory=$(mktemp -d "${TMPDIR:-/tmp}/namesnap-winner-music.XXXXXX")
trap 'rm -rf "$working_directory"' EXIT
seed_directory="$working_directory/seeds"
mkdir -p "$seed_directory"

# Every source is CC0 music documented by its Freesound page as 128 BPM or
# faster. Fields: slug|BPM|preview URL.
sources=(
  "happy-dance-140|140|https://cdn.freesound.org/previews/398/398941_3082984-lq.mp3"
  "future-bass-150|150|https://cdn.freesound.org/previews/427/427847_4067257-lq.mp3"
  "dance-loop-128|128|https://cdn.freesound.org/previews/434/434103_4397472-hq.mp3"
  "melody-mix-128|128|https://cdn.freesound.org/previews/415/415511_5232403-hq.mp3"
  "happy-cave-130|130|https://cdn.freesound.org/previews/435/435531_3283808-hq.mp3"
  "rock-metal-160|160|https://cdn.freesound.org/previews/633/633807_4294742-hq.mp3"
  "industrial-techno-130|130|https://cdn.freesound.org/previews/841/841527_1694253-lq.mp3"
  "melodic-house-128|128|https://cdn.freesound.org/previews/211/211549_1676145-lq.mp3"
  "nineties-beat-140|140|https://cdn.freesound.org/previews/330/330744_5770690-lq.mp3"
  "hard-edm-140|140|https://cdn.freesound.org/previews/554/554147_7724198-lq.mp3"
  "retro-game-beat-140|140|https://cdn.freesound.org/previews/691/691609_14802701-lq.mp3"
  "electronic-loop-153|153.41|https://cdn.freesound.org/previews/276/276674_3611100-lq.mp3"
  "electronic-drums-153|153.41|https://cdn.freesound.org/previews/276/276671_3611100-lq.mp3"
  "trap-loop-140|140|https://cdn.freesound.org/previews/852/852261_12574855-lq.mp3"
)

for source_record in "${sources[@]}"; do
  IFS='|' read -r source_slug source_bpm source_url <<< "$source_record"
  curl --fail --location --silent --show-error "$source_url" \
    --output "$seed_directory/$source_slug.mp3"
done

for track_number in $(seq 1 100); do
  zero_based=$((track_number - 1))
  source_index=$((zero_based % ${#sources[@]}))
  variation=$((zero_based / ${#sources[@]}))
  source_record=${sources[$source_index]}
  IFS='|' read -r source_slug source_bpm source_url <<< "$source_record"
  source_file="$seed_directory/$source_slug.mp3"
  output_file=$(printf '%s/winner_music_%03d.mp3' "$output_directory" "$track_number")

  case "$variation" in
    0) style_filter="equalizer=f=90:t=q:w=1:g=2,equalizer=f=8500:t=q:w=1:g=2" ;;
    1) style_filter="equalizer=f=110:t=q:w=1:g=4,acompressor=threshold=.12:ratio=2.5:attack=10:release=120" ;;
    2) style_filter="equalizer=f=6000:t=q:w=1:g=4,equalizer=f=250:t=q:w=1:g=-1" ;;
    3) style_filter="acompressor=threshold=.10:ratio=3.5:attack=5:release=80,equalizer=f=100:t=q:w=1:g=3" ;;
    4) style_filter="aecho=.8:.55:45:.12,equalizer=f=7500:t=q:w=1:g=2" ;;
    5) style_filter="flanger=delay=2:depth=1.5:regen=0:width=60:speed=.3,equalizer=f=100:t=q:w=1:g=2" ;;
    6) style_filter="atempo=1.04,equalizer=f=115:t=q:w=1:g=3,equalizer=f=7000:t=q:w=1:g=2" ;;
    7) style_filter="atempo=1.08,acompressor=threshold=.11:ratio=3:attack=6:release=90,equalizer=f=120:t=q:w=1:g=3" ;;
    *) echo "Unsupported variation $variation" >&2; exit 70 ;;
  esac

  ffmpeg -hide_banner -loglevel error -stream_loop -1 -i "$source_file" -vn \
    -af "aresample=44100,highpass=f=35,$style_filter,loudnorm=I=-14:TP=-1.2:LRA=7,atrim=duration=8,afade=t=out:st=7.65:d=0.35" \
    -t 8 -ar 44100 -ac 2 -codec:a libmp3lame -b:a 128k \
    -metadata title="NameSnap Winner Music $(printf '%03d' "$track_number")" \
    -metadata comment="CC0 source $source_slug at $source_bpm BPM; mix variation $variation" \
    -y "$output_file"
done

track_count=$(find "$output_directory" -maxdepth 1 -type f -name 'winner_music_*.mp3' | wc -l | tr -d ' ')
if [[ "$track_count" != "100" ]]; then
  echo "Expected 100 generated tracks, found $track_count" >&2
  exit 65
fi

for output_file in "$output_directory"/winner_music_*.mp3; do
  duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$output_file")
  if ! awk -v duration="$duration" 'BEGIN { exit !(duration >= 5.8) }'; then
    echo "Track is shorter than 5.8 seconds: $output_file ($duration)" >&2
    exit 65
  fi
done

echo "Generated and validated 100 NameSnap winner tracks in $output_directory"
