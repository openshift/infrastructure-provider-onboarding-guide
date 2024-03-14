FROM registry.access.redhat.com/ubi9/ubi AS builder

COPY . /opt
WORKDIR /opt

RUN yum -y install python3 python3-pip \
    && pip install -r requirements.txt \
    && mkdocs build

FROM registry.access.redhat.com/ubi8/ubi
RUN yum -y install python3 && pip3 install twisted
COPY --from=builder /opt/site /opt/site

WORKDIR /opt/site
CMD twistd --nodaemon --pidfile /tmp/twistd.pid web --path . --listen tcp:8080
