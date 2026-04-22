[ "${RMLWK_LIB_UTIL:-0}" -eq 1 ] && return 0
RMLWK_LIB_UTIL=1

tolower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

ensure_parent_dir() {
    mkdir -p "$(dirname "$1")"
}

ensure_file() {
    ensure_parent_dir "$1"
    touch "$1"
}

ensure_trailing_newline() {
    file="$1"
    [ -s "$file" ] || return 0
    last_char=$(tail -c 1 "$file" 2>/dev/null || true)
    [ -n "$last_char" ] && echo "" >> "$file"
}

get_prop() {
    key="$1"
    file="$2"
    [ -f "$file" ] || return 1
    grep -m 1 "^${key}=" "$file" 2>/dev/null | cut -d= -f2-
}

set_prop() {
    key="$1"
    value="$2"
    file="$3"

    if grep -q "^${key}=" "$file" 2>/dev/null; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$file"
    else
        ensure_trailing_newline "$file"
        echo "${key}=${value}" >> "$file"
    fi
}

add_entry() {
    entry="$1"
    file="$2"
    ensure_file "$file"
    grep -Fqx "$entry" "$file" 2>/dev/null && return 0
    ensure_trailing_newline "$file"
    echo "$entry" >> "$file"
}

remove_entry() {
    entry="$1"
    file="$2"
    field_index="${3:-0}"
    tmp_file="${file}.tmp.$$"

    ensure_file "$file"
    if [ "$field_index" -gt 0 ] 2>/dev/null; then
        awk -v entry="$entry" -v field_index="$field_index" '
            field_index > NF || $field_index != entry { print }
        ' "$file" > "$tmp_file"
    else
        grep -Fvx "$entry" "$file" > "$tmp_file" 2>/dev/null || :
    fi
    mv "$tmp_file" "$file"
}

count_entries() {
    file="$1"
    [ -f "$file" ] || { echo 0; return 0; }
    grep -c '^[^#[:space:]]' "$file" 2>/dev/null || echo 0
}

list_source_urls_from_file() {
    file="$1"
    [ -f "$file" ] || return 0
    awk '
        /^# OFF # / { print $4; next }
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
        { print $1 }
    ' "$file"
}

source_url_exists_in_file() {
    url="$1"
    file="$2"
    list_source_urls_from_file "$file" | grep -Fxq "$url"
}

append_hosts_entry() {
    file="$1"
    ip="$2"
    domain="$3"
    ensure_file "$file"
    ensure_trailing_newline "$file"
    echo "$ip $domain" >> "$file"
}

reset_hosts() {
    printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
}

# Resolve a profile file: user profiles take precedence over built-ins.
# Outputs the path of the resolved file, or empty string if not found.
resolve_profile_file() {
    name="$1"
    user_profile="$persist_dir/profiles/${name}.txt"
    builtin_profile="$MODDIR/profiles/${name}.txt"
    if [ -f "$user_profile" ]; then
        echo "$user_profile"
    elif [ -f "$builtin_profile" ]; then
        echo "$builtin_profile"
    fi
}

get_current_time() {
    time_ns=$(date +%s%N 2>/dev/null)
    if [ $? -ne 0 ] || [ "$time_ns" = "%s%N" ]; then
        time_ms=$(($(date +%s) * 1000))
    else
        time_ms=$((time_ns / 1000000))
    fi
    echo "$time_ms"
}

format_duration() {
    local duration_ms=$1
    local minutes=$(( duration_ms / 60000 ))
    local remainder=$(( duration_ms % 60000 ))
    local seconds=$(( remainder / 1000 ))
    local milliseconds=$(( remainder % 1000 ))
    local parts=""

    if [ "$minutes" -gt 0 ]; then
        parts="${minutes}m"
    fi

    if [ "$seconds" -gt 0 ]; then
        if [ -z "$parts" ]; then
            parts="${seconds}s"
        else
            parts="$parts, ${seconds}s"
        fi
    fi

    if [ "$milliseconds" -gt 0 ] || [ -z "$parts" ]; then
        if [ -z "$parts" ]; then
            parts="${milliseconds}ms"
        else
            parts="$parts and ${milliseconds}ms"
        fi
    fi

    [ -n "$parts" ] || parts="0ms"
    echo "$parts"
}

log_duration() {
    local job_name="$1"
    local start_time="$2"
    local end_time="$3"
    local duration_ms=$(( end_time - start_time ))
    [ "$duration_ms" -lt 0 ] && duration_ms=$(( -duration_ms ))
    local formatted_time
    formatted_time=$(format_duration "$duration_ms")
    log_message SUCCESS "Task [$job_name] took $formatted_time"
}

abort() {
    type log_message >/dev/null 2>&1 && log_message ERROR "Aborting: $1"
    echo "[✗] $1"
    sleep 0.5
    exit 1
}
