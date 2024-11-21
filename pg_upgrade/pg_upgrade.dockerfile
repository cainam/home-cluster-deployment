FROM myregistry.adm13:443/tools/mypy:3.12.4-slim

RUN apt update
RUN apt upgrade -y

RUN apt install -y postgresql-common
RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

RUN apt install -y postgresql-16 postgresql-17

RUN userdel postgres && (groupdel postgres; true) && groupadd --gid 70 postgres && useradd --uid 70 --gid 70 postgres
RUN chown postgres /var/run/postgresql/
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

WORKDIR /tmp
ADD pg_upgrade.sh /


