FROM freeradius/freeradius-server:latest-3.2

# Update apt package lists to allow installing new software
RUN apt-get update

# We need Git to be able to clone the `freeradius-oauth2-perl` repository
RUN apt-get install -y git
# Required dependencies for running `freeradius-oauth2-perl`
RUN apt-get -y install --no-install-recommends ca-certificates curl libjson-pp-perl libwww-perl

# Enable additional modules, as needed
RUN ln -s /etc/freeradius/mods-available/sql /etc/freeradius/mods-enabled/
RUN ln -s /etc/freeradius/mods-available/redis /etc/freeradius/mods-enabled/

# Install the `freeradius-oauth2-perl` module
RUN git clone https://github.com/jimdigriz/freeradius-oauth2-perl.git /opt/freeradius-oauth2-perl/

RUN printf '\n$INCLUDE /opt/freeradius-oauth2-perl/dictionary\n' >> /etc/freeradius/dictionary

COPY ./config/freeradius-oauth2-perl/ /opt/freeradius-oauth2-perl/
RUN ln -s /opt/freeradius-oauth2-perl/module /etc/freeradius/mods-enabled/oauth2
RUN ln -s /opt/freeradius-oauth2-perl/policy /etc/freeradius/policy.d/oauth2

COPY ./config/unix-timestamp.sh /usr/local/bin/unix-timestamp.sh

# Overwrite configuration files with our customized versions
COPY ./config/freeradius/ /etc/raddb
