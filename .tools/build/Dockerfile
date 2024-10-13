FROM cypress/included:13.14.2

# Install git, supervisor, VNC, & X11 packages
RUN set -ex; \
    apt-get update; \
    apt-get install -y \
      apt-utils \
      bash \
      curl \
      fluxbox \
      git \
      net-tools \
      novnc \
      supervisor \
      x11vnc \
      xvfb \
      xterm \
      dialog \
      gnupg2;
    #   chromium \
    #   firefox-esr;

# Run Firefox-esr in Cypress Gui
# RUN unlink /usr/bin/firefox.real && ln -s /usr/bin/firefox-esr /usr/bin/firefox.real

# Install VSCodium
# RUN wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

# RUN echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | tee /etc/apt/sources.list.d/vscodium.list

# RUN apt-get update; \
    # apt-get install -y \
    # codium;

# Install Sublime Text
RUN wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
RUN echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list

RUN apt-get update && apt-get install -y \
    sublime-text

# Setup inital environment variables
ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:0.0 \
    DISPLAY_WIDTH=1024 \
    DISPLAY_HEIGHT=768 \
    RUN_FLUXBOX=yes \
    JC_OVERRIDE_FILES=yes \
    JC_OVERRIDE_BACKUP=yes

# there is a built-in user "node" that comes from the very base Docker Node image
# we are going to recreate this user and give it _same id_ as external user
# that is going to run this container.
ARG USER_ID=${USER_ID:-0}
ARG GROUP_ID=${GROUP_ID:-0}

# if you want to see all existing groups uncomment the next command
# RUN cat /etc/group

# do not log creating new user, otherwise there could be a lot of messages
RUN userdel -f node \
    && if getent passwd ${USER_ID}; then usermod -u 1000 $(id -u -n ${USER_ID}); fi \
    && if getent group node ; then groupdel node; fi \
    && if getent group ${GROUP_ID} ; then groupmod -g 1000 $(getent group ${GROUP_ID} | cut -d: -f1); fi \
    && groupadd -g ${GROUP_ID} node \
    && useradd -l -u ${USER_ID} -g node node \
    && install -d -m 0755 -o node -g node /home/node

# RUN id -nu $USER_ID

# move test runner binary folder to the non-root's user home directory
RUN mv /root/.cache /home/node/.cache
# make sure cypress looks in the right place
ENV CYPRESS_CACHE_FOLDER=/home/node/.cache/Cypress

COPY ./novnc /novnc
COPY ./entrypoint.sh /entrypoint.sh
RUN chown -R ${USER_ID}:${GROUP_ID} "/novnc"
RUN chown -R ${USER_ID}:${GROUP_ID} "/root/.npm"

RUN if [ -f /root/.fluxbox/menu ]; then mv /root/.fluxbox/menu /root/.fluxbox/menu.bak; fi
COPY ./fluxbox/fluxbox-menu /root/.fluxbox/menu
RUN chmod -R 777 /root/.fluxbox

USER node
# show user effective id and group - it should be non-zero
# meaning the current user is not root
# RUN id

# Only for debugging purposes
# RUN chmod +x /entrypoint.sh
# CMD ["/entrypoint.sh"]

EXPOSE 5800

ENTRYPOINT ["/entrypoint.sh"]

# This line sets up a health check for the container.
HEALTHCHECK --interval=6s --timeout=10s --start-period=3s --retries=5 CMD curl -f http://127.0.0.1:5800/vnc.html || exit 1
