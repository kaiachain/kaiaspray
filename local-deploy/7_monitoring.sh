#!/bin/bash

pushd .
trap 'popd' EXIT

HOMEDIR="$(dirname "$0")"
cd $HOMEDIR

# Create necessary directories if they don't exist
mkdir -p monitoring/prometheus
mkdir -p monitoring/grafana/provisioning/datasources
mkdir -p monitoring/grafana/provisioning/dashboards

# Function to setup Grafana dashboards
setup_grafana_dashboards() {
  # Get the absolute path of the script directory
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  # Copy Grafana configuration files from roles/monitor-init/files/grafana/dashboards
  cp "${SCRIPT_DIR}/../roles/monitor-init/files/grafana/dashboards/"*.json monitoring/grafana/provisioning/dashboards/
  cp "${SCRIPT_DIR}/../roles/monitor-init/files/grafana/dashboards/kaia-dashboard.yml" monitoring/grafana/provisioning/dashboards/

  # Generate grafana-dashboard config file
  printf "%s\n" "apiVersion: 1" \
                "providers:" \
                "- name: 'klaytn'" \
                "  folder: ''" \
                "  options:" \
                "    path: /etc/grafana/provisioning/dashboards" > monitoring/grafana/provisioning/dashboards/klaytn-dashboard.yml
}

# Function to generate Prometheus config
generate_prometheus_config() {
  source ./properties.sh
  
  printf "%s\n" "global:" \
                "  evaluation_interval: 5s" \
                "  scrape_interval: 5s" \
                "" \
                "scrape_configs:" \
                "- job_name: 'kaia'" \
                "  static_configs:" > monitoring/prometheus/prometheus.yml

  # Add targets for all nodes
  # CN nodes
  for (( i=0; i<NUMOFCN; i++ ))
  do
    printf "  - targets:\n" >> monitoring/prometheus/prometheus.yml
    printf "    - \"host.docker.internal:%d\"\n" $((61001 + i)) >> monitoring/prometheus/prometheus.yml
    printf "    labels:\n" >> monitoring/prometheus/prometheus.yml
    printf "      node_type: \"cn\"\n" >> monitoring/prometheus/prometheus.yml
    printf "      name: \"cn%d\"\n" $((i + 1)) >> monitoring/prometheus/prometheus.yml
    printf "      instance: \"cn%d\"\n" $((i + 1)) >> monitoring/prometheus/prometheus.yml
  done

  # PN nodes
  for (( i=0; i<NUMOFPN; i++ ))
  do
    printf "  - targets:\n" >> monitoring/prometheus/prometheus.yml
    printf "    - \"host.docker.internal:%d\"\n" $((61001 + NUMOFCN + i)) >> monitoring/prometheus/prometheus.yml
    printf "    labels:\n" >> monitoring/prometheus/prometheus.yml
    printf "      node_type: \"pn\"\n" >> monitoring/prometheus/prometheus.yml
    printf "      name: \"pn%d\"\n" $((i + 1)) >> monitoring/prometheus/prometheus.yml
    printf "      instance: \"pn%d\"\n" $((i + 1)) >> monitoring/prometheus/prometheus.yml
  done

  # EN nodes
  for (( i=0; i<NUMOFEN; i++ ))
  do
    printf "  - targets:\n" >> monitoring/prometheus/prometheus.yml
    printf "    - \"host.docker.internal:%d\"\n" $((61001 + NUMOFCN + NUMOFPN + i)) >> monitoring/prometheus/prometheus.yml
    printf "    labels:\n" >> monitoring/prometheus/prometheus.yml
    printf "      node_type: \"en\"\n" >> monitoring/prometheus/prometheus.yml
    printf "      name: \"en%d\"\n" $((i + 1)) >> monitoring/prometheus/prometheus.yml
    printf "      instance: \"en%d\"\n" $((i + 1)) >> monitoring/prometheus/prometheus.yml
  done

  echo "Generated Prometheus config with ${NUMOFCN} CN, ${NUMOFPN} PN, and ${NUMOFEN} EN nodes"
}

# Function to generate Grafana datasource config
generate_grafana_config() {
  printf "%s\n" "apiVersion: 1" \
                "datasources:" \
                "- name: klaytn" \
                "  type: prometheus" \
                "  access: proxy" \
                "  url: http://prometheus:9090" \
                "  isDefault: true" > monitoring/grafana/provisioning/datasources/prometheus.yml
}

case "$1" in
    start)
        echo "Starting monitoring tools..."
        generate_prometheus_config
        generate_grafana_config
        setup_grafana_dashboards
        docker-compose up -d
        echo "Prometheus is available at http://localhost:9090"
        echo "Grafana is available at http://localhost:3000 (admin/admin)"
        ;;
    stop)
        echo "Stopping monitoring tools..."
        docker-compose down
        echo "Monitoring tools stopped"
        ;;
    url)
        echo "prometheus:http://localhost:9090"
        echo "grafana:http://localhost:3000"
        ;;
    *)
        echo "Usage: $0 {start|stop|url}"
        exit 1
        ;;
esac