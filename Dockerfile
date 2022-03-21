FROM registry.access.redhat.com/ubi8/ubi AS builder

RUN yum -y install python3 && pip3 install mkdocs

COPY . /opt
WORKDIR /opt
RUN mkdocs build

FROM docker.io/nginx:latest
COPY --from=builder /opt/site /usr/share/nginx/html
