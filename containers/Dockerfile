FROM httpd:2.4

RUN sed -i 's#AllowOverride [Nn]one#AllowOverride All#' /usr/local/apache2/conf/httpd.conf
RUN sed -i 's-CustomLog /proc/self/fd/1 common-CustomLog /proc/self/fd/1 combined-' /usr/local/apache2/conf/httpd.conf

COPY ./build/web/ /usr/local/apache2/htdocs/
