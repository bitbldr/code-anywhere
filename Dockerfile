FROM codercom/code-server:latest

USER root

RUN apt-get update -y
RUN apt-get install -y supervisor

# install docker
RUN apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
RUN apt-get update -y
RUN apt-cache policy docker-ce
RUN apt-get install -y docker-ce
RUN curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose
RUN usermod -aG docker coder

# # install node and localtunnel
# RUN apt-get install -y nodejs npm
# RUN npm install -g localtunnel

# install ngrok
RUN apt-get install -y unzip jq
RUN curl -Lo /ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip \
 && unzip -o /ngrok.zip -d /bin \
 && rm -f /ngrok.zip
 
# Add config script.
COPY --chown=coder ngrok.yml /home/coder/.ngrok2/
COPY ngrok-info.sh /bin/ngrok-info
RUN chmod +x /bin/ngrok-info

# supervisord configuration
COPY supervisord.conf /etc/supervisord.conf

ARG USER_ID
ARG GROUP_ID

RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
    userdel -f coder &&\
    if getent group coder ; then groupdel coder; fi &&\
    groupadd -g ${GROUP_ID} coder &&\
    useradd -l -u ${USER_ID} -g coder coder &&\
    install -d -m 0755 -o coder -g coder /home/coder &&\
    chown --changes --silent --no-dereference --recursive \
          --from=1000:1000 ${USER_ID}:${GROUP_ID} \
        /home/coder \
;fi

USER coder

ENTRYPOINT ["supervisord", "-c", "/etc/supervisord.conf", "-n"]