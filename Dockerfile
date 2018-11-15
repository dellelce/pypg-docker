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

# Static building of "psycopg2" currently fails at linking if static_libpq is set = 1
# Will have to add a static libpq for that to work.
# Keeping lines temporary here while working out best way to do it.
#
#    && tar  xmzf $f \
#    && ls -lt . \
#    && mydir=$(ls -t | head -1) \
#    && echo $mydir \
#    && sed -i 's/static_libpq = 0/static_libpq = 1/' $mydir/setup.cfg \
#    && cat $mydir/setup.cfg \
#    && pip wheel $mydir/ \

RUN    apk add gcc bash wget perl perl-dev file xz make libc-dev linux-headers g++ sed \
    && mkdir /app/v \
    && cd /app/v \
    && ${INSTALLDIR}/bin/python3 -m venv . \
    && . bin/activate \
    && export PATH=/app/pg/bin:$PATH \
    && wget -q -O srcget.tar.gz $SRCGET \
    && tar xzf srcget.tar.gz \
    && f=$( ./srcget-master/srcget.sh -n psycopg ) \
    && pip install -U pip setuptools wheel \
    && pip wheel $f \
    && mkdir binaries \
    && mv *.whl binaries

#
FROM dellelce/py-base as delivery

# Use shared lib for now
COPY --from=pgbuild /app/pg/lib/libpq*so.*[1-9] ${INSTALLDIR}/lib/

# "." is a Directory even if it does not end with "/", Dear Mr Docker.
COPY --from=pgbuild /app/v/binaries ./

# note that variables are local to each "FROM"
RUN    ${INSTALLDIR}/bin/pip3 install -q -U pip setuptools \
    && ${INSTALLDIR}/bin/pip3 install *.whl \
    && ${INSTALLDIR}/bin/python3 -m pip list \
    && echo 'import psycopg2; print("And the pyscopg2 version is " + psycopg2.__version__);' | \
       ${INSTALLDIR}/bin/python3 \
    && rm *.whl

