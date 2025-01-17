FROM debian:latest AS neovim

RUN <<EOF
apt-get update
apt-get install -y ninja-build gettext cmake unzip curl build-essential git
git clone https://github.com/neovim/neovim.git /root/neovim
cd /root/neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
make install
rm -rf /root/neovim
apt-get remove -y ninja-build gettext cmake unzip curl build-essential git
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*
EOF

FROM debian:latest

COPY --from=neovim /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=neovim /usr/local/lib/nvim /usr/local/lib/nvim
COPY --from=neovim /usr/local/share/nvim /usr/local/share/nvim

RUN <<EOF
apt-get update
apt-get -y install curl git unzip zsh tmux fzf ripgrep fd-find nmap zsh-autosuggestions zsh-syntax-highlighting nodejs npm ruby ruby-dev python3 python3-venv direnv
npm install -g tree-sitter-cli
npm install -g bun
rm -rf /var/lib/apt/lists/*
EOF

RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/zsh-theme-powerlevel10k

ENV TERM=xterm-256color
ENV SHELL=/bin/zsh
ENV LANG=en_CA.UTF-8
ARG PUID=1000 PGID=1000

RUN <<EOF
id -g ${PGID} 2>/dev/null
[ $? -ne 0 ] && groupadd -g ${PGID} ubuntu

id ${PUID} 2>/dev/null
[ $? -ne 0 ] && useradd -lm -u ${PUID} -g ${PGID} ubuntu

usermod -aG ${PGID} -s /bin/zsh $(id -nu ${PUID})
EOF

USER ${PUID}

RUN <<EOF
if [ "${PUID}" -eq "0" ]; then
  cd /root
else
  cd /home/$(id -nu "${PUID}")
fi

/usr/share/zsh-theme-powerlevel10k/gitstatus/install

git config --global init.defaultBranch main
git config --global user.name "Zhuoran Tan"
git config --global user.email "me@zhuorant.com"

git clone https://github.com/zhuorantan/dotfiles.git
cd dotfiles
sed -i 's/-b v2.1.3 //' ./Makefile
make ohmyzsh
make tmux
make link

nvim --headless "+Lazy! sync" "+TSUpdateSync" "+sleep 10" +qa

mkdir workspaces
EOF

ENTRYPOINT [ "zsh" ]
