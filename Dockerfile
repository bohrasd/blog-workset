FROM node:latest
COPY id_rsa /root/.ssh/id_rsa
RUN npm config set registry https://registry.npm.taobao.org \
    && npm install hexo-cli font-spider --ignore-scripts -g \
    && echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config
WORKDIR /var/www/myblog
COPY ./blog/package.json ./
RUN yarn
COPY ./blog /var/www/myblog
RUN git config --global user.email "bohrasdf@gmail.com" \
    && git config --global user.name "bohrasd"
EXPOSE 4000
RUN hexo generate \
    && font-spider --ignore "font-awesome\.css$,bootstrap\.min\.css$" public/**/*.html \
    && mv themes/cactus-light/layout/_partial/head.ejs themes/cactus-light/layout/_partial/head.ejs.2 \
    && mv themes/cactus-light/layout/_partial/head.ejs.1 themes/cactus-light/layout/_partial/head.ejs \
    && hexo generate
CMD hexo server
