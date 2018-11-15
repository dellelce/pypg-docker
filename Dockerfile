# use  base (=raw from mkit) PostGreSQL & Python install to build the latest psycopg2
ARG BASE=dellelce/pgbase
FROM $BASE as build

LABEL maintainer="Antonio Dell'Elce"

RUN    mv ${INSTALLDIR} /app/_pg \
    && ls -lt /app

# stage to build a "real wheel"....
FROM dellelce/py-base as pgbuild

COPY --from=build /app/_pg /app/pg

ARG SRCGET=http://github.com/dellelce/srcget/archive/master.tar.gz

RUN    apk add gcc bash wget perl perl-dev file xz make libc-dev linux-headers g++ sed \
    && mkdir /app/v \
    && cd /app/v \
    && ${INSTALLDIR}/bin/python3 -m venv . \
    && . bin/activate \
    && export PATH=/app/pg/bin:$PATH \
    && wget -q -O srcget.tar.gz $SRCGET \
    && tar xzf srcget.tar.gz \
    && f=$( ./srcget-master/srcget.sh -n psycopg ) \
    && echo $f \
    && pip install -U pip setuptools wheel \
    && tar  xmzf $f \
    && ls -lt . \
    && mydir=$(ls -t | head -1) \
    && echo $mydir \
    && sed -i 's/static_libpq = 0/static_libpq = 1/' $mydir/setup.cfg \
    && cat $mydir/setup.cfg \
    && pip wheel $mydir/ \
    && mkdir binaries \
    && mv *.whl binaries

#
FROM dellelce/py-base as delivery

# "." is a Directory even if it does not end with "/", Dear Mr Docker.
COPY --from=pgbuild /app/v/binaries ./

# note that variables are local to each "FROM"
RUN    ls -lt \
    && ${INSTALLDIR}/bin/python3 -m pip install -U pip setuptools \
    && ${INSTALLDIR}/bin/python3 -m pip install *.whl \
    && ${INSTALLDIR}/bin/python3 -m pip list

