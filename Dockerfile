FROM node:latest
COPY id_rsa /home/node/.ssh/id_rsa
RUN chmod 700 /home/node/.ssh/id_rsa \
    && chown 1000:1000 /home/node/.ssh/id_rsa \
    && npm config set registry https://registry.npm.taobao.org \
    && npm install hexo-cli font-spider --ignore-scripts -g \
    && echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /home/node/.ssh/config
WORKDIR /var/www/myblog
COPY ./blog/package.json ./blog/yarn.lock ./
RUN yarn \
    && git config --global user.email "bohrasdf@gmail.com" \
    && git config --global user.name "bohrasd"
COPY ./blog /var/www/myblog
RUN chown 1000:1000 /var/www/myblog/ -R
USER node
EXPOSE 4000
RUN hexo generate \
    && font-spider --ignore "font-awesome\.css$,bootstrap\.min\.css$" public/**/*.html \
    && mv themes/wind/layout/_partial/head.ejs themes/wind/layout/_partial/head.ejs.2 \
    && mv themes/wind/layout/_partial/head.ejs.1 themes/wind/layout/_partial/head.ejs \
    && hexo generate
CMD hexo server
