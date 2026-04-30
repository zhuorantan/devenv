#!/usr/bin/env bash
set -euo pipefail

die() {
    printf 'docker-entrypoint: %s\n' "$*" >&2
    exit 1
}

log() {
    printf 'docker-entrypoint: %s\n' "$*" >&2
}

is_uint() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

user=""
while IFS=: read -r name _ _ _ _ home shell; do
    if [[ "$home" == /home/* && "$shell" != */nologin && "$shell" != */false ]]; then
        user="$name"
        break
    fi
done < <(getent passwd)
[[ -n "$user" ]] || die "could not find a regular user with a home directory under /home"
id "$user" >/dev/null 2>&1 || die "user '$user' does not exist"

uid="${HOST_UID:-$(id -u "$user")}"
gid="${HOST_GID:-$(id -g "$user")}"

is_uint "$uid" || die "HOST_UID must be a numeric uid, got '$uid'"
is_uint "$gid" || die "HOST_GID must be a numeric gid, got '$gid'"

if [[ "$(id -u)" != "0" ]]; then
    die "entrypoint must run as root; do not start this container with Docker --user"
fi

home_dir="$(getent passwd "$user" | cut -d: -f6)"
target_home="$home_dir"
target_uid="$uid"
target_gid="$gid"
if [[ "$uid" == "0" ]]; then
    target_home=/root
    target_uid=0
    target_gid=0
fi

home_template=/usr/local/share/devenv/home
home_seed_marker="${target_home}/.devenv-home-seeded"
if [[ -d "$target_home" && -d "$home_template" && ! -e "$home_seed_marker" ]]; then
    log "seeding $target_home from image template"
    cp -aT "$home_template" "$target_home"
    touch "$home_seed_marker"
fi

if [[ -d "$target_home" ]]; then
    current_uid="$(stat -c '%u' "$target_home")"
    current_gid="$(stat -c '%g' "$target_home")"
    if [[ "$current_uid" != "$target_uid" || "$current_gid" != "$target_gid" ]]; then
        log "fixing ownership for $target_home to $target_uid:$target_gid"
        chown -R "$target_uid:$target_gid" "$target_home"
    fi
fi

if [[ "$uid" == "0" ]]; then
    exec "$@"
fi

[[ "$gid" != "0" ]] || die "refusing to remap '$user' to gid 0 with non-root uid $uid"

if ! getent group "$gid" >/dev/null; then
    groupmod --gid "$gid" "$user"
elif [[ "$(getent group "$gid" | cut -d: -f1)" != "$user" ]]; then
    existing_group="$(getent group "$gid" | cut -d: -f1)"
    usermod --gid "$gid" "$user"
    usermod --append --groups "$existing_group" "$user"
else
    usermod --gid "$gid" "$user"
fi

if [[ "$(id -u "$user")" != "$uid" ]]; then
    usermod --uid "$uid" "$user"
fi

if [[ -S /var/run/docker.sock ]]; then
    docker_gid="$(stat -c '%g' /var/run/docker.sock)"
    if ! getent group "$docker_gid" >/dev/null; then
        groupadd --gid "$docker_gid" docker-host
    fi
    docker_group="$(getent group "$docker_gid" | cut -d: -f1)"
    usermod --append --groups "$docker_group" "$user"
fi

exec su --command "$@" --login "$user"
