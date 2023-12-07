FROM registry.access.redhat.com/ubi8/ubi AS builder

RUN yum -y install python3 \
  && pip3 install mkdocs pymdown-extensions

COPY . /opt
WORKDIR /opt
RUN mkdocs build

FROM registry.access.redhat.com/ubi8/ubi
RUN yum -y install python3 && pip3 install twisted
COPY --from=builder /opt/site /opt/site

WORKDIR /opt/site
CMD twistd --nodaemon --pidfile /tmp/twistd.pid web --path . --listen tcp:8080
