# NameSnap winner media sources

NameSnap ships exactly 100 distinct winner tracks on iOS and web. Every track
is music—not a standalone sound effect—and derives from a CC0 source documented
at 128 BPM or faster. Every bundled file is approximately eight seconds long,
exceeding the app's 5.8-second celebration window. Source pages and CC0 status
were verified on August 26, 2026. CC0 permits copying, modification, distribution, and
commercial use without required attribution.

| Source index | Source title | Creator | BPM | Source | Preview | License |
| ---: | --- | --- | ---: | --- | --- | --- |
| 1 | HappyLoop.wav | envirOmaniac2 | 140 | https://freesound.org/s/398941/ | https://cdn.freesound.org/previews/398/398941_3082984-lq.mp3 | CC0 |
| 2 | 150bpm Saw Chords - Future Bass | newagesoup | 150 | https://freesound.org/s/427847/ | https://cdn.freesound.org/previews/427/427847_4067257-lq.mp3 | CC0 |
| 3 | Loop 128 Bpm | deleted_user_4397472 | 128 | https://freesound.org/s/434103/ | https://cdn.freesound.org/previews/434/434103_4397472-hq.mp3 | CC0 |
| 4 | Melody Loop Mix 128 bpm | Vannipat | 128 | https://freesound.org/s/415511/ | https://cdn.freesound.org/previews/415/415511_5232403-hq.mp3 | CC0 |
| 5 | happy cave | ADnova | 130 | https://freesound.org/s/435531/ | https://cdn.freesound.org/previews/435/435531_3283808-hq.mp3 | CC0 |
| 6 | Rock Short 24 | bainmack | 160 | https://freesound.org/s/633807/ | https://cdn.freesound.org/previews/633/633807_4294742-hq.mp3 | CC0 |
| 7 | Techno Loop 130 bpm | numerocuatro | 130 | https://freesound.org/s/841527/ | https://cdn.freesound.org/previews/841/841527_1694253-lq.mp3 | CC0 |
| 8 | 128 bpm house loop | waveplaySFX | 128 | https://freesound.org/s/211549/ | https://cdn.freesound.org/previews/211/211549_1676145-lq.mp3 | CC0 |
| 9 | 90s Beat Loop 140bpm | AlonnaAllen | 140 | https://freesound.org/s/330744/ | https://cdn.freesound.org/previews/330/330744_5770690-lq.mp3 | CC0 |
| 10 | Hard EDM Drum Loop 140 BPM | Fupicat | 140 | https://freesound.org/s/554147/ | https://cdn.freesound.org/previews/554/554147_7724198-lq.mp3 | CC0 |
| 11 | Retro Style Game Beat | BenDerhover | 140 | https://freesound.org/s/691609/ | https://cdn.freesound.org/previews/691/691609_14802701-lq.mp3 | CC0 |
| 12 | tXgOtX153.41-02 | tXgix | 153.41 | https://freesound.org/s/276674/ | https://cdn.freesound.org/previews/276/276674_3611100-lq.mp3 | CC0 |
| 13 | tXgDrX153.41-02 | tXgix | 153.41 | https://freesound.org/s/276671/ | https://cdn.freesound.org/previews/276/276671_3611100-lq.mp3 | CC0 |
| 14 | Dark Trap Loop #2 C#min 140 BPM | holizna | 140 | https://freesound.org/s/852261/ | https://cdn.freesound.org/previews/852/852261_12574855-lq.mp3 | CC0 |

## Output mapping

Files are named `winner_music_001.mp3` through `winner_music_100.mp3`. For
output number `n`, the source index is `((n - 1) mod 14) + 1`, and the mix
variation is `floor((n - 1) / 14)`. The eight deterministic variations cover
club EQ, bass emphasis, bright dance EQ, punch compression, short dance echo,
flanging, and two tempo-increased mixes. No variation slows its source, so all
outputs remain at least 128 BPM.

The reproducible generator is `scripts/generate-winner-music.sh`. It creates
eight-second, stereo, 128 kbps MP3s, normalizes loudness, limits peaks, and
adds a short fade. The iOS and web builds ship byte-identical copies. No source
name, creator name, or third-party brand is presented in the product UI.

## Winner visual assets

| Bundled file | Origin | Source | License / rights note |
| --- | --- | --- | --- |
| `dancer.png` | Original NameSnap raster sticker generated with OpenAI image generation | Local production asset | Original commissioned asset; no external character, logo, celebrity, or brand reference |
| `guitarist.png` | Original NameSnap raster sticker generated with OpenAI image generation | Local production asset | Original commissioned asset; no external musician, band, logo, celebrity, or brand reference |
| `dynamite.png` | Original NameSnap raster sticker generated with OpenAI image generation | Local production asset | Original commissioned theatrical-cartoon asset; no real weapon, damage, or third-party brand reference |
| `hype-mascot.png` | Original NameSnap raster sticker generated with OpenAI image generation | Local production asset | Original commissioned abstract mascot; no external character, logo, or brand reference |
| `pixel-bomb.gif` | Animated bomb explosion by Bobjt and ansimuz | https://opengameart.org/content/animated-bomb-explosion | CC0; attribution not required |
| `confetti-burst.gif` | Confetti Effect Spritesheet by jellyfizh | https://opengameart.org/content/confetti-effect-spritesheet | CC0; converted from the 8×8 PNG sprite sheet into a 64-frame GIF |

Do not replace a bundled file without recording and verifying its source and
commercial-use license here first.
