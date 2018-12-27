FROM node:latest
COPY id_rsa /home/node/.ssh/id_rsa
RUN npm config set registry https://registry.npm.taobao.org \
    && npm install hexo-cli font-spider -g \
    && chmod 700 /home/node/.ssh/id_rsa \
    && chown 1000:1000 /home/node/.ssh/id_rsa \
    && echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /home/node/.ssh/config
USER node
EXPOSE 4000
VOLUME [ "/var/www/myblog" ]
WORKDIR /var/www/myblog
COPY ./blog /var/www/myblog
RUN npm install \
    && git config --global user.email "bohrasdf@gmail.com" \
    && git config --global user.name "bohrasd"
CMD hexo server