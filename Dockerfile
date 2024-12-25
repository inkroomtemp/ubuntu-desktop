# ------------------------------------------------------------------------------
# Pull base image
FROM ubuntu:jammy
LABEL author="Brett Kuskie <fullaxx@gmail.com>"

# ------------------------------------------------------------------------------
# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV WINDOWMANAGER=openbox
ENV LANG=C.UTF-8
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME /usr/local/rustup
ENV PATH ${PATH}:${CARGO_HOME}/bin
ENV TZ=Asia/Shanghai
ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup

RUN dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) sed -i "s@http://.*archive.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list && sed -i "s@http://.*security.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list ;; \
        arm64) sed -i "s@http://ports.ubuntu.com@https://mirrors.huaweicloud.com@g" /etc/apt/sources.list
        ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}" ;; \
    esac; 

# ------------------------------------------------------------------------------
# Install tigervnc,openbox and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      fcitx5 \
      fonts-wqy-zenhei \
      git \
      zsh \
      vim \
      ca-certificates \
      curl \
      dbus-x11 \
      fbpanel \
      hsetroot \
      less \
      locales \
      nano \
      obconf \
      openbox \
      sudo \
      tigervnc-common \
      tigervnc-standalone-server \
      tigervnc-tools \
      tzdata \
      wget \
      x11-utils \
      x11-xserver-utils \
      xfonts-base \
      xterm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# ------------------------------------------------------------------------------
# Configure locale
RUN echo "LC_ALL=zh_CN.UTF-8" >> /etc/environment && \
    echo "LANG=zh_CN.UTF-8" > /etc/locale.conf && \
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen
    
# ------------------------------------------------------------------------------
# Configure XTerm
RUN sed -e 's/saveLines: 1024/saveLines: 8192/' -i /etc/X11/app-defaults/XTerm
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && rustup target add $(arch)-unknown-linux-musl \
    && REPO=sjtug/ohmyzsh REMOTE=https://git.sjtu.edu.cn/${REPO}.git sh -c "$(curl -fsSL https://git.sjtu.edu.cn/sjtug/ohmyzsh/-/raw/master/tools/install.sh\?inline\=false)"

RUN echo "export CARGO_HOME=${CARGO_HOME}" >> /etc/profile \
    && echo "export RUSTUP_HOME=${RUSTUP_HOME}" >> /etc/profile \
    && v=$(rustc --version | awk '{print $2}') \
    && echo "export RUST_VERSION=$v" >> /etc/profile \
    && echo "export PATH=${PATH}" >> /etc/profile \
    && echo "export CARGO_HOME=${CARGO_HOME}" >> /root/.zshrc \
    && echo "export RUSTUP_HOME=${RUSTUP_HOME}" >> /root/.zshrc \
    && echo "export RUST_VERSION=$v" >> /root/.zshrc \
    && echo "export PATH=${PATH}" >> /root/.zshrc

# ------------------------------------------------------------------------------
# Configure openbox
RUN mkdir -p /usr/share/ubuntu-desktop/openbox && \
    cat /etc/xdg/openbox/rc.xml \
      | sed -e 's@<number>4</number>@<number>8</number>@' \
      > /usr/share/ubuntu-desktop/openbox/rc.xml

# ------------------------------------------------------------------------------
# Install scripts and configuration files
COPY app/app.sh app/imagestart.sh app/tiger.sh /app/
COPY bin/set_wallpaper.sh /usr/bin/
COPY conf/xstartup /usr/share/ubuntu-desktop/vnc/
COPY conf/autostart conf/menu.xml /usr/share/ubuntu-desktop/openbox/
COPY conf/fbpaneldefault /usr/share/ubuntu-desktop/fbpanel/default
COPY conf/sudo /usr/share/ubuntu-desktop/sudo
COPY conf/bash.colors conf/color_prompt.sh conf/lang.sh /opt/bash/
COPY scripts/*.sh /app/scripts/

RUN sh /app/scripts/prepare_firefox_ppa.sh && apt update -y && apt install -y firefox
# ------------------------------------------------------------------------------
# Expose ports
EXPOSE 5901

# ------------------------------------------------------------------------------
# Define default command
CMD ["/app/app.sh"]
