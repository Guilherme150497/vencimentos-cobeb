# Vencimentos COBEB — página única (index.html) servida por nginx na VM da Cobeb (stack "vencimentos" no Dockhand).
# Não há build: a imagem só copia o index.html. Os dados e o login ficam no Supabase (chave publicável no próprio HTML).
FROM nginx:alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
