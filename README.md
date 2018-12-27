# bohrasd-blog-workset

copy id_rsa file to the directory

edit index.ejs before font-spider command. change style.css to absolute path

docker-compose exec myblog font-spider --ignore "font-awesome\\.css$,bootstrap\\.min\\.css$" public/**/*.html
