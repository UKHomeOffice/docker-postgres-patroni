# This dockerfile is meant to help with setup and testing of
# patroni nodes.  It is designed to use kubernetes to support
# multiple nodes

FROM ukhomeofficedigital/centos-base

ENV DATA_DIR=/var/lib/pgsql \
    PGUSER=postgres

ADD ./scripts/ /scripts/
ADD ./patroni/ /patroni/

RUN /scripts/package_install.sh

RUN /scripts/file_setup.sh

EXPOSE 8001 5432

ENTRYPOINT ["/bin/bash", "/scripts/entrypoint.sh"]
#USER postgres
