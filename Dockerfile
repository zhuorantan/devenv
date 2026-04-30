FROM opensuse/tumbleweed:latest

ARG DEVENV_USER=me

RUN if [ "$(uname -m)" = "aarch64" ]; then \
    zypper --non-interactive addrepo \
    http://download.opensuse.org/ports/aarch64/tumbleweed/repo/non-oss/ \
    repo-non-oss; \
    fi && \
    zypper --non-interactive refresh && \
    zypper --non-interactive install --no-recommends \
    bubblewrap \
    docker \
    docker-compose \
    fd \
    fzf \
    gcc \
    git \
    glibc-locale \
    iproute2 \
    less \
    make \
    net-tools \
    neovim \
    nodejs \
    npm \
    nmap \
    openssh \
    python3 \
    ripgrep \
    ruby \
    ruby-devel \
    sudo \
    terminfo \
    terminfo-ghostty \
    tmux \
    which \
    yazi \
    zsh && \
    npm install -g bun && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/zsh-theme-powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh-syntax-highlighting && \
    mkdir -p /usr/share/zsh-theme-powerlevel10k/gitstatus/usrbin && \
    GITSTATUS_CACHE_DIR=/usr/share/zsh-theme-powerlevel10k/gitstatus/usrbin \
    /usr/share/zsh-theme-powerlevel10k/gitstatus/install

RUN set -eux; \
    groupadd "${DEVENV_USER}" && \
    useradd \
    --create-home \
    --gid "${DEVENV_USER}" \
    --shell /bin/zsh \
    "${DEVENV_USER}" && \
    usermod --shell /bin/zsh root && \
    printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${DEVENV_USER}" > "/etc/sudoers.d/${DEVENV_USER}" && \
    chmod 0440 "/etc/sudoers.d/${DEVENV_USER}" && \
    mkdir -p /run/tmux && \
    chmod 1777 /run/tmux && \
    mkdir -p /workspace && \
    chown "${DEVENV_USER}:${DEVENV_USER}" /workspace

USER ${DEVENV_USER}
WORKDIR /home/${DEVENV_USER}

ENV BUN_INSTALL="/home/${DEVENV_USER}/.bun"

RUN set -eux; \
    bun install -g @openai/codex && \
    git clone https://github.com/zhuorantan/dotfiles.git && \
    cd dotfiles && \
    make ohmyzsh && \
    make tmux && \
    make link && \
    echo 'source ~/.zshenv' > ~/.zprofile

USER root

RUN set -eux; \
    mkdir -p /usr/local/share/devenv/home && \
    cp -aT "/home/${DEVENV_USER}" /usr/local/share/devenv/home

COPY entrypoint.sh /

WORKDIR /workspace

ENV LANG=en_CA.UTF-8
ENV SHELL=/bin/zsh
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

ENTRYPOINT ["/entrypoint.sh"]
