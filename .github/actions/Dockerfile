FROM registry.access.redhat.com/ubi8/ubi

RUN dnf install -y python39
RUN pip3 install mkdocs

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
