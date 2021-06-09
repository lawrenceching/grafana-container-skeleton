FROM grafana/grafana
USER root
RUN apk add --no-cache curl
USER grafana
COPY init.sh /init.sh
COPY dashboards /data/dashboards
ENTRYPOINT [ "bash", "-c", "/init.sh" ]