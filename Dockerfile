# Dev container base com Debian, Homebrew, mise e ferramentas de desenvolvimento
FROM debian:bookworm-slim

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Dependências base do sistema (SEM bibliotecas do Playwright)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    sudo \
    locales \
    procps \
    file \
    ruby \
    xclip \
    xsel \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Usuário não-root
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

# Homebrew
ENV HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew \
    HOMEBREW_CELLAR=/home/linuxbrew/.linuxbrew/Cellar \
    HOMEBREW_REPOSITORY=/home/linuxbrew/.linuxbrew/Homebrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
ENV PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"

# mise (gerenciador de versões)
RUN brew install mise \
    && echo 'eval "$(mise activate bash)"' >> ~/.bashrc

# Ferramentas CLI via Homebrew
RUN brew install \
    ripgrep \
    fzf \
    fd \
    yazi \
    tmux \
    stow \
    neovim \
    zoxide \
    eza \
    jq \
    lsof \
    starship \
    lazygit \
    gh \
    openssh

# Node.js via mise
ENV MISE_DATA_DIR=/home/dev/.local/share/mise
ENV PATH="${MISE_DATA_DIR}/shims:${PATH}"
RUN mise use --global node@24

# Claude Code CLI (instalador padrão)
RUN curl -fsSL https://claude.ai/install.sh | sh
ENV PATH="/home/dev/.claude/local/bin:${PATH}"

# zsh + oh-my-zsh
RUN brew install zsh \
    && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc \
    && echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# Plugins do zsh
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# TPM (Tmux Plugin Manager)
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Shell padrão zsh
RUN sudo chsh -s /home/linuxbrew/.linuxbrew/bin/zsh dev
ENV SHELL=/home/linuxbrew/.linuxbrew/bin/zsh

# Diretórios
RUN mkdir -p ~/.config
RUN sudo mkdir -p /workspaces && sudo chown dev:dev /workspaces
WORKDIR /workspaces

CMD ["/home/linuxbrew/.linuxbrew/bin/zsh"]
