#!/usr/bin/env bash
# ============================================================
# transcribe.sh
# Batch transcribe media files with whisper.cpp (whisper-cli)
#
# Usage:
#   ./transcribe.sh [INPUT_DIR] [OUTPUT_DIR]
#
# Env:
#   MODEL_NAME=large-v3-q5_0
#   CHUNK_SECONDS=300
#   FALLBACK_CHUNK_SECONDS=60
#   RETRY_ON_JUNK=1
#   INTERACTIVE=1
#   VERBOSE=0
#   WHISPER_PROGRESS=1
#   COLOR=1
#
# Notes:
# - If run in a TTY and INTERACTIVE=1, you'll be prompted for
#   input/output folders and model selection.
# - Models are stored in ./models next to this script.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IN_DIR="${1:-./transcribe_in}"
OUT_DIR="${2:-./transcribe_out}"

MODEL_NAME="${MODEL_NAME:-large-v3-q5_0}"
CHUNK_SECONDS="${CHUNK_SECONDS:-60}"                    # default 60s
FALLBACK_CHUNK_SECONDS="${FALLBACK_CHUNK_SECONDS:-20}"  # retry split size
RETRY_ON_JUNK="${RETRY_ON_JUNK:-1}"
INTERACTIVE="${INTERACTIVE:-1}"
VERBOSE="${VERBOSE:-0}"
WHISPER_PROGRESS="${WHISPER_PROGRESS:-1}"
COLOR="${COLOR:-1}"

MODELS_DIR="${SCRIPT_DIR}/models"
MODEL_PATH=""
DOWNLOADER=""
DOWNLOADER_TMPDIR=""

need_cmd() { command -v "$1" >/dev/null 2>&1; }

refresh_model_path() {
  MODEL_PATH="${MODELS_DIR}/ggml-${MODEL_NAME}.bin"
}

cleanup_downloader() {
  if [[ -n "${DOWNLOADER_TMPDIR:-}" && -d "$DOWNLOADER_TMPDIR" ]]; then
    rm -rf "$DOWNLOADER_TMPDIR"
  fi
}

is_tty() { [[ -t 0 && -t 1 ]]; }

log() {
  if [[ "$VERBOSE" == "1" ]]; then
    echo "$@"
  fi
}

init_colors() {
  if [[ "$COLOR" == "1" && -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_CYAN=$'\033[36m'
    C_YELLOW=$'\033[33m'
  else
    C_RESET=""
    C_BOLD=""
    C_RED=""
    C_GREEN=""
    C_CYAN=""
    C_YELLOW=""
  fi
}

cprint() {
  local color="$1"
  shift
  printf "%b\n" "${color}$*${C_RESET}"
}

info() { cprint "$C_CYAN" "$@"; }
warn() { printf "%b\n" "${C_YELLOW}$*${C_RESET}" >&2; }
err() { printf "%b\n" "${C_RED}$*${C_RESET}" >&2; }
success() { cprint "$C_GREEN" "$@"; }

run_whisper() {
  if [[ "$VERBOSE" == "1" ]]; then
    whisper-cli "$@"
    return
  fi

  if [[ "$WHISPER_PROGRESS" == "1" ]]; then
    whisper-cli "$@" 2>&1 | awk '
      /progress/ {
        if (match($0, /[0-9][0-9]*%/)) {
          pct=substr($0, RSTART, RLENGTH-1)
          printf("\r  progress %3s%%", pct)
          fflush()
          last=1
        }
      }
      END {
        if (last) {
          print ""
        }
      }
    '
  else
    whisper-cli "$@" >/dev/null 2>&1
  fi
}

expand_path() {
  local path="$1"
  case $path in
    ~) echo "$HOME" ;;
    ~/*)
      echo "$HOME/${path:2}"
      ;;
    *)
      echo "$path"
      ;;
  esac
}

prompt_input() {
  local label="$1"
  local default="$2"
  local input
  read -r -p "${C_BOLD}${C_CYAN}${label}${C_RESET} [${default}]: " input
  echo "${input:-$default}"
}

prompt_number() {
  local label="$1"
  local default="$2"
  local input
  while true; do
    read -r -p "${C_BOLD}${C_CYAN}${label}${C_RESET} [${default}]: " input
    if [[ -z "$input" ]]; then
      echo "$default"
      return
    fi
    if [[ "$input" =~ ^[0-9]+$ ]]; then
      echo "$input"
      return
    fi
    warn "Please enter a whole number."
  done
}

prompt_yes_no() {
  local label="$1"
  local default="$2"
  local input
  local suffix
  if [[ "$default" == "1" ]]; then
    suffix="Y/n"
  else
    suffix="y/N"
  fi
  read -r -p "${C_BOLD}${C_CYAN}${label}${C_RESET} [${suffix}]: " input
  case "${input,,}" in
    y|yes) echo 1 ;;
    n|no) echo 0 ;;
    "") echo "$default" ;;
    *) echo "$default" ;;
  esac
}

list_local_models() {
  shopt -s nullglob
  local m
  for m in "$MODELS_DIR"/ggml-*.bin; do
    basename "$m" | sed 's/^ggml-//; s/\.bin$//'
  done
  shopt -u nullglob
}

list_remote_models() {
  if ! ensure_downloader 1; then
    return 0
  fi

  awk '
    BEGIN { in_list=0 }
    /^[[:space:]]*(models|models_all|all_models|models_available|models_list)[[:space:]]*=/ {
      in_list=1
      line=$0
      sub(/^[^=]+=[[:space:]]*/, "", line)
      gsub(/[()]/, " ", line)
      gsub(/"/, "", line)
      gsub(/\047/, "", line)
      n=split(line, a, /[^A-Za-z0-9._-]+/)
      for (i=1; i<=n; i++) if (a[i] != "") print a[i]
      if ($0 ~ /\)/) in_list=0
      next
    }
    in_list==1 {
      line=$0
      if (line ~ /\)/) { sub(/\).*/, "", line); in_list=0 }
      gsub(/[()]/, " ", line)
      gsub(/"/, "", line)
      gsub(/\047/, "", line)
      n=split(line, a, /[^A-Za-z0-9._-]+/)
      for (i=1; i<=n; i++) if (a[i] != "") print a[i]
    }
  ' "$DOWNLOADER" | awk 'NF' | awk '!seen[$0]++' | awk '!/^(list|available|models|model|list_models|models_list)$/'
}

prompt_model() {
  local current="$1"
  local models_local=()
  local models_remote=()
  local line
  while read -r line; do
    [[ -n "$line" ]] && models_local+=("$line")
  done < <(list_local_models)

  while read -r line; do
    [[ -n "$line" ]] && models_remote+=("$line")
  done < <(list_remote_models)

  # Remove remote models that are already local
  if [[ "${#models_remote[@]}" -gt 0 && "${#models_local[@]}" -gt 0 ]]; then
    local filtered_remote=()
    local r l dup
    for r in "${models_remote[@]}"; do
      dup=0
      for l in "${models_local[@]}"; do
        if [[ "$r" == "$l" ]]; then
          dup=1
          break
        fi
      done
      [[ "$dup" -eq 0 ]] && filtered_remote+=("$r")
    done
    models_remote=("${filtered_remote[@]}")
  fi

  local models=("${models_local[@]}" "${models_remote[@]}")
  if [[ "${#models[@]}" -gt 0 ]]; then
    local i=1
    echo "${C_BOLD}Choose model (number or name)${C_RESET} [${current}]: " >&2
    for line in "${models[@]}"; do
      local origin="remote"
      local l
      for l in "${models_local[@]}"; do
        if [[ "$line" == "$l" ]]; then
          origin="local"
          break
        fi
      done
      if [[ "$origin" == "local" ]]; then
        echo "  $i) $line [${C_GREEN}${origin}${C_RESET}]" >&2
      else
        echo "  $i) $line [${C_CYAN}${origin}${C_RESET}]" >&2
      fi
      i=$((i + 1))
    done
    local choice
    read -r -p "${C_BOLD}${C_CYAN}Choice${C_RESET}: " choice
    if [[ -z "$choice" ]]; then
      echo "$current"
      return
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      if [[ "$choice" -ge 1 && "$choice" -le "${#models[@]}" ]]; then
        echo "${models[$((choice - 1))]}"
        return
      fi
      echo "${C_YELLOW}Invalid choice.${C_RESET} Type a model name or press Enter to keep default." >&2
      read -r -p "Model name: " choice
      echo "${choice:-$current}"
      return
    fi
    echo "$choice"
    return
  fi

  read -r -p "Model name [${current}]: " line
  echo "${line:-$current}"
}

maybe_interactive_setup() {
  if [[ "$INTERACTIVE" != "1" ]]; then
    return
  fi
  if ! is_tty; then
    return
  fi

  init_colors
  echo "${C_BOLD}Interactive setup${C_RESET} (press Enter for defaults)"
  local in_dir out_dir
  in_dir="$(prompt_input "Input folder" "$IN_DIR")"
  out_dir="$(prompt_input "Output folder" "$OUT_DIR")"
  IN_DIR="$(expand_path "$in_dir")"
  OUT_DIR="$(expand_path "$out_dir")"
  MODEL_NAME="$(prompt_model "$MODEL_NAME")"
  CHUNK_SECONDS="$(prompt_number "Chunk length in seconds" "$CHUNK_SECONDS")"
  FALLBACK_CHUNK_SECONDS="$(prompt_number "Fallback chunk length when stuck (0 = disable)" "$FALLBACK_CHUNK_SECONDS")"
  RETRY_ON_JUNK="$(prompt_yes_no "Retry on repeated/junk output" "$RETRY_ON_JUNK")"
}

ensure_homebrew() {
  if need_cmd brew; then return; fi
  err "Homebrew not found. Install it from https://brew.sh and re-run."
  exit 1
}

ensure_deps() {
  ensure_homebrew

  if ! need_cmd ffmpeg; then
    log "Installing ffmpeg..."
    brew install ffmpeg
  fi

  if ! need_cmd whisper-cli; then
    log "Installing whisper-cpp (provides whisper-cli)..."
    brew install whisper-cpp
  fi

  local share
  share="$(brew --prefix whisper-cpp)/share/whisper-cpp"
  if [[ -d "$share" ]]; then
    export GGML_METAL_PATH_RESOURCES="$share"
  fi
}

ensure_downloader() {
  local allow_fail="${1:-0}"
  mkdir -p "$MODELS_DIR"

  if [[ -n "${DOWNLOADER:-}" && -x "$DOWNLOADER" ]]; then
    return 0
  fi

  DOWNLOADER_TMPDIR="$(mktemp -d)"
  DOWNLOADER="${DOWNLOADER_TMPDIR}/download-ggml-model.sh"
  trap cleanup_downloader EXIT

  local brew_prefix
  local brew_script
  brew_prefix="$(brew --prefix whisper-cpp 2>/dev/null || true)"
  brew_script="${brew_prefix}/share/whisper-cpp/models/download-ggml-model.sh"
  if [[ -n "$brew_prefix" && -f "$brew_script" ]]; then
    cp -f "$brew_script" "$DOWNLOADER"
    chmod +x "$DOWNLOADER"
    return
  fi

  log "Fetching model downloader script..."
  if ! curl -fsSL \
    -o "$DOWNLOADER" \
    "https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/models/download-ggml-model.sh"; then
    if [[ "$allow_fail" == "1" ]]; then
      return 1
    fi
    err "Failed to fetch model downloader script."
    exit 1
  fi
  chmod +x "$DOWNLOADER"
}

ensure_model() {
  refresh_model_path
  if [[ -f "$MODEL_PATH" ]]; then
    return
  fi

  ensure_downloader

  log "Downloading model: ${MODEL_NAME}"
  log "Target path: ${MODEL_PATH}"
  log ""

  (
    cd "$SCRIPT_DIR"
    bash "$DOWNLOADER" "$MODEL_NAME"
  )

  if [[ ! -f "$MODEL_PATH" ]]; then
    local fallback_path
    fallback_path="$(find "$DOWNLOADER_TMPDIR" -name "ggml-${MODEL_NAME}.bin" -print -quit 2>/dev/null || true)"
    if [[ -n "${fallback_path:-}" ]]; then
      mv -f "$fallback_path" "$MODEL_PATH"
    fi
  fi

  if [[ ! -f "$MODEL_PATH" ]]; then
    err "Model download ran, but file not found at:"
    err "  $MODEL_PATH"
    exit 1
  fi
}

detect_junk_txt() {
  local txt="$1"
  [[ -f "$txt" ]] || return 1

  local top_count
  top_count="$(
    tr -d '\r' < "$txt" \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | awk 'NF' \
    | sort | uniq -c | sort -nr | head -n 1 | awk '{print $1}'
  )"

  [[ "${top_count:-0}" -ge 20 ]]
}

abs_path() {
  local p="$1"
  if [[ -d "$p" ]]; then
    (cd "$p" && pwd -P)
  else
    local d b
    d="$(dirname "$p")"
    b="$(basename "$p")"
    (cd "$d" && printf "%s/%s" "$(pwd -P)" "$b")
  fi
}

sanitize_name() {
  local name="$1"
  name="${name##*/}"
  name="${name#.}"
  if [[ -z "$name" ]]; then
    echo "file"
  else
    echo "$name"
  fi
}

append_shifted_srt() {
  local input="$1"
  local offset_ms="$2"
  local output="$3"
  local start_index="$4"

  awk -v offset="$offset_ms" -v idx="$start_index" '
    function to_ms(ts,   parts,h,m,s,ms) {
      split(ts, parts, /[:,]/)
      h=parts[1]+0; m=parts[2]+0; s=parts[3]+0; ms=parts[4]+0
      return ((h*3600 + m*60 + s)*1000 + ms)
    }
    function from_ms(ms,   h,m,s,ms2) {
      if (ms < 0) ms = 0
      h=int(ms/3600000); ms%=3600000
      m=int(ms/60000); ms%=60000
      s=int(ms/1000); ms2=ms%1000
      return sprintf("%02d:%02d:%02d,%03d", h,m,s,ms2)
    }
    /^[0-9]+$/ { next }
    /--> / {
      split($0, a, / --> /)
      start=to_ms(a[1]) + offset
      end=to_ms(a[2]) + offset
      print idx
      print from_ms(start) " --> " from_ms(end)
      idx++
      next
    }
    { print }
  ' "$input" >> "$output"
}

append_shifted_vtt() {
  local input="$1"
  local offset_ms="$2"
  local output="$3"

  awk -v offset="$offset_ms" '
    function to_ms(ts,   parts,h,m,s,ms) {
      split(ts, parts, /[:.]/)
      h=parts[1]+0; m=parts[2]+0; s=parts[3]+0; ms=parts[4]+0
      return ((h*3600 + m*60 + s)*1000 + ms)
    }
    function from_ms(ms,   h,m,s,ms2) {
      if (ms < 0) ms = 0
      h=int(ms/3600000); ms%=3600000
      m=int(ms/60000); ms%=60000
      s=int(ms/1000); ms2=ms%1000
      return sprintf("%02d:%02d:%02d.%03d", h,m,s,ms2)
    }
    BEGIN { in_header=1 }
    /^WEBVTT/ { next }
    in_header && /^[[:space:]]*$/ { next }
    /--> / {
      split($0, a, / --> /)
      start_ts=a[1]
      rest=a[2]
      end_ts=rest
      suffix=""
      if (match(rest, / /)) {
        end_ts=substr(rest, 1, RSTART-1)
        suffix=substr(rest, RSTART)
      }
      start=to_ms(start_ts) + offset
      end=to_ms(end_ts) + offset
      print from_ms(start) " --> " from_ms(end) suffix
      next
    }
    { print }
  ' "$input" >> "$output"
}

split_to_chunks_wav() {
  local input="$1"
  local chunk_dir="$2"
  local seconds="${3:-$CHUNK_SECONDS}"
  local ffmpeg_stats=("-nostats")
  if [[ "$VERBOSE" == "1" ]]; then
    ffmpeg_stats=("-stats")
  fi
  mkdir -p "$chunk_dir"

  ffmpeg -hide_banner -loglevel error "${ffmpeg_stats[@]}" -y \
    -i "$input" \
    -ar 16000 -ac 1 \
    -f segment -segment_time "$seconds" -reset_timestamps 1 \
    "${chunk_dir}/chunk_%03d.wav"
}

transcribe_chunk() {
  local wav="$1"
  local out_prefix="$2"

  run_whisper \
    -m "$MODEL_PATH" \
    -f "$wav" \
    -otxt -osrt -ovtt \
    -of "$out_prefix" \
    -pp
}

transcribe_chunk_strict() {
  # Strict mode using YOUR build's flags (from your help output)
  local wav="$1"
  local out_prefix="$2"

  run_whisper \
    -m "$MODEL_PATH" \
    -f "$wav" \
    -otxt -osrt -ovtt \
    -of "$out_prefix" \
    -pp \
    -nf \
    -tp 0.0 \
    -bs 1 \
    -bo 1 \
    -nth 0.6 \
    -lpt -1.0
}

transcribe_chunk_with_fallback() {
  local wav="$1"
  local out_prefix="$2"
  local out_txt="${out_prefix}.txt"
  local out_srt="${out_prefix}.srt"
  local out_vtt="${out_prefix}.vtt"
  local fallback_used=0

  transcribe_chunk "$wav" "$out_prefix"

  if [[ "$RETRY_ON_JUNK" == "1" ]] && detect_junk_txt "$out_txt"; then
    warn "Detected repeated/junk output. Retrying strict..."
    rm -f "$out_txt" "${out_prefix}.srt" "${out_prefix}.vtt"
    transcribe_chunk_strict "$wav" "$out_prefix"
  fi

  if [[ "$RETRY_ON_JUNK" == "1" ]] && detect_junk_txt "$out_txt"; then
    if [[ "$FALLBACK_CHUNK_SECONDS" -gt 0 ]]; then
      fallback_used=1
      warn "Still repetitive. Splitting chunk into ${FALLBACK_CHUNK_SECONDS}s subchunks..."
      rm -f "$out_txt" "${out_prefix}.srt" "${out_prefix}.vtt"

      local fallback_dir="${out_prefix}_fallback"
      local fallback_wav_dir="${fallback_dir}/wav"
      local fallback_txt_dir="${fallback_dir}/txt"

      rm -rf "$fallback_dir"
      mkdir -p "$fallback_wav_dir" "$fallback_txt_dir"

      split_to_chunks_wav "$wav" "$fallback_wav_dir" "$FALLBACK_CHUNK_SECONDS"

      local -a SUBCHUNKS
      mapfile -t SUBCHUNKS < <(ls -1 "${fallback_wav_dir}"/chunk_*.wav 2>/dev/null | sort)
      if [[ "${#SUBCHUNKS[@]}" -eq 0 ]]; then
        err "Fallback split produced no subchunks."
        exit 1
      fi

      : > "$out_txt"
      : > "$out_srt"
      printf "WEBVTT\n\n" > "$out_vtt"
      local srt_index=1
      local vtt_started=0
      local sub_i=0
      local sub
      for sub in "${SUBCHUNKS[@]}"; do
        local sub_name sub_prefix sub_txt
        sub_name="$(basename "$sub" .wav)"
        sub_prefix="${fallback_txt_dir}/${sub_name}"
        sub_txt="${sub_prefix}.txt"
        local sub_srt="${sub_prefix}.srt"
        local sub_vtt="${sub_prefix}.vtt"

        transcribe_chunk_strict "$sub" "$sub_prefix"
        [[ -f "$sub_txt" ]] || { err "Fallback missing output: $sub_txt"; exit 1; }
        cat "$sub_txt" >> "$out_txt"
        printf "\n\n" >> "$out_txt"

        local offset_ms=$((sub_i * FALLBACK_CHUNK_SECONDS * 1000))
        if [[ -f "$sub_srt" ]]; then
          if [[ -s "$out_srt" ]]; then
            printf "\n" >> "$out_srt"
          fi
          append_shifted_srt "$sub_srt" "$offset_ms" "$out_srt" "$srt_index"
          local srt_count
          srt_count="$(awk '/-->/ {c++} END{print c+0}' "$sub_srt")"
          srt_index=$((srt_index + srt_count))
        fi
        if [[ -f "$sub_vtt" ]]; then
          if [[ "$vtt_started" -eq 1 ]]; then
            printf "\n" >> "$out_vtt"
          fi
          append_shifted_vtt "$sub_vtt" "$offset_ms" "$out_vtt"
          vtt_started=1
        fi
        sub_i=$((sub_i + 1))
      done
    fi
  fi

  if [[ "$RETRY_ON_JUNK" == "1" ]] && detect_junk_txt "$out_txt"; then
    warn "Warning: repeated output persists after fallback."
  fi

  if [[ "$fallback_used" == "1" ]] && [[ ! -f "$out_srt" || ! -f "$out_vtt" ]]; then
    warn "Warning: fallback did not produce srt/vtt for $out_prefix"
  fi
}

main() {
  init_colors
  ensure_deps
  maybe_interactive_setup
  ensure_model

  if [[ ! -d "$IN_DIR" ]]; then
    err "Input folder not found: $IN_DIR"
    exit 1
  fi

  mkdir -p "$OUT_DIR"

  log "Input        : $IN_DIR"
  log "Output       : $OUT_DIR"
  log "Model        : $MODEL_NAME ($MODEL_PATH)"
  log "Chunk seconds: $CHUNK_SECONDS (default 60s)"
  log "Fallback     : $FALLBACK_CHUNK_SECONDS (seconds, 0 disables)"
  log "Retry on junk: $RETRY_ON_JUNK"
  log ""

  mapfile -d '' FILES < <(
    find "$IN_DIR" -type f \( \
      -iname "*.wav" -o -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.mp4" -o -iname "*.mov" -o -iname "*.aac" -o -iname "*.flac" -o -iname "*.ogg" \
    \) -print0
  )

  local total_files="${#FILES[@]}"
  if [[ "$total_files" -eq 0 ]]; then
    warn "No supported media files found in: $IN_DIR"
    exit 0
  fi

  local in_dir_abs
  in_dir_abs="$(abs_path "$IN_DIR")"

  local fi=0
  for input in "${FILES[@]}"; do
    fi=$((fi + 1))

    local input_abs rel_path base_name base_dir chunk_dir txt_dir combined_txt combined_srt combined_vtt
    input_abs="$(abs_path "$input")"
    if [[ "$input_abs" == "$in_dir_abs/"* ]]; then
      rel_path="${input_abs#$in_dir_abs/}"
    else
      rel_path="$(basename "$input_abs")"
    fi
    base_name="$(sanitize_name "$(basename "$rel_path")")"
    base_dir="${OUT_DIR}/${rel_path}"
    chunk_dir="${base_dir}/chunks"
    txt_dir="${base_dir}/chunks_txt"
    combined_txt="${base_dir}/${base_name}.combined.txt"
    combined_srt="${base_dir}/${base_name}.combined.srt"
    combined_vtt="${base_dir}/${base_name}.combined.vtt"

    mkdir -p "$chunk_dir" "$txt_dir"

    log ""
    log "=============================="
    log "[$fi/$total_files] Input: $input"
    log "[$fi/$total_files] Out  : $base_dir"
    log "=============================="

    log "[$fi/$total_files] Splitting into ${CHUNK_SECONDS}s chunks..."
    rm -f "${chunk_dir}/chunk_"*.wav 2>/dev/null || true
    split_to_chunks_wav "$input" "$chunk_dir" "$CHUNK_SECONDS"

    mapfile -t CHUNKS < <(ls -1 "${chunk_dir}"/chunk_*.wav 2>/dev/null | sort)
    local total_chunks="${#CHUNKS[@]}"
    if [[ "$total_chunks" -eq 0 ]]; then
      err "[$fi/$total_files] ERROR: no chunks produced."
      exit 1
    fi

    local ci=0
    for wav in "${CHUNKS[@]}"; do
      ci=$((ci + 1))

      local chunk_name out_prefix out_txt
      chunk_name="$(basename "$wav" .wav)"
      out_prefix="${txt_dir}/${chunk_name}"
      out_txt="${out_prefix}.txt"

      info "[$fi/$total_files][$ci/$total_chunks] $(basename "$input") / $(basename "$wav")"
      transcribe_chunk_with_fallback "$wav" "$out_prefix"

      if [[ ! -f "$out_txt" ]]; then
        err "[$fi/$total_files][$ci/$total_chunks] ERROR: missing output: $out_txt"
        exit 1
      fi

      log "[$fi/$total_files][$ci/$total_chunks] OK"
    done

    log ""
    log "[$fi/$total_files] Combining chunk transcripts:"
    log "[$fi/$total_files]   txt: $combined_txt"
    log "[$fi/$total_files]   srt: $combined_srt"
    log "[$fi/$total_files]   vtt: $combined_vtt"
    : > "$combined_txt"
    : > "$combined_srt"
    printf "WEBVTT\n\n" > "$combined_vtt"
    local srt_index=1
    local vtt_started=0
    local chunk_i=0
    for wav in "${CHUNKS[@]}"; do
      local chunk_name out_txt out_srt out_vtt
      chunk_name="$(basename "$wav" .wav)"
      out_txt="${txt_dir}/${chunk_name}.txt"
      out_srt="${txt_dir}/${chunk_name}.srt"
      out_vtt="${txt_dir}/${chunk_name}.vtt"
      if [[ -f "$out_txt" ]]; then
        cat "$out_txt" >> "$combined_txt"
        printf "\n\n" >> "$combined_txt"
      fi

      local offset_ms=$((chunk_i * CHUNK_SECONDS * 1000))
      if [[ -f "$out_srt" ]]; then
        if [[ -s "$combined_srt" ]]; then
          printf "\n" >> "$combined_srt"
        fi
        append_shifted_srt "$out_srt" "$offset_ms" "$combined_srt" "$srt_index"
        local srt_count
        srt_count="$(awk '/-->/ {c++} END{print c+0}' "$out_srt")"
        srt_index=$((srt_index + srt_count))
      fi
      if [[ -f "$out_vtt" ]]; then
        if [[ "$vtt_started" -eq 1 ]]; then
          printf "\n" >> "$combined_vtt"
        fi
        append_shifted_vtt "$out_vtt" "$offset_ms" "$combined_vtt"
        vtt_started=1
      fi
      chunk_i=$((chunk_i + 1))
    done

    if [[ "$VERBOSE" == "1" ]]; then
      success "[$fi/$total_files] DONE: $combined_txt"
    fi
  done

  if [[ "$VERBOSE" == "1" ]]; then
    success ""
    success "All done."
  fi
}

main
