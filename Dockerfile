# Сборочный образ для release-артефактов (AppImage).
#
# Зачем контейнер, если на хосте всё собирается: AppImage НЕ бандлит glibc — он
# кладёт внутрь системные библиотеки сборочной машины, а те требуют её glibc.
# Собранный на Arch артефакт требовал glibc 2.43 и не запускался нигде, кроме
# rolling-дистрибутивов. Ubuntu 22.04 даёт glibc 2.35 и покрывает Ubuntu 22.04+,
# Debian 12+, Fedora 36+. Правило простое: собирать на самом старом дистрибутиве,
# который хочешь поддерживать.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Системные зависимости Tauri v2 + то, что нужно linuxdeploy (file, wget, desktop-file-utils).
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential curl wget file ca-certificates git \
      libwebkit2gtk-4.1-dev libgtk-3-dev librsvg2-dev \
      libayatana-appindicator3-dev libssl-dev pkg-config \
      desktop-file-utils patchelf unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Rust и bun ставим в общесистемные пути: контейнер запускается от uid хоста
# (иначе артефакты в примонтированном дереве окажутся root-owned), а значит
# $HOME внутри может быть не записываемым.
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    BUN_INSTALL=/usr/local/bun \
    PATH=/usr/local/cargo/bin:/usr/local/bun/bin:$PATH

RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable \
    && chmod -R a+rwX /usr/local/rustup /usr/local/cargo

RUN curl -fsSL https://bun.sh/install | bash \
    && chmod -R a+rwX /usr/local/bun

# linuxdeploy — сам AppImage, а в контейнере без --privileged нет FUSE и он не
# смонтируется. Штатный обход: распаковать и запустить.
ENV APPIMAGE_EXTRACT_AND_RUN=1 \
    NO_STRIP=1

WORKDIR /src
