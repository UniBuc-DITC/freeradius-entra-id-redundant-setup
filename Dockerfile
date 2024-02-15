FROM freeradius/freeradius-server:latest-3.2

COPY ./config/freeradius/ /etc/raddb/
