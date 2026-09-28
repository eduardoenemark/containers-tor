#!/bin/bash
MODE=${1:-client}
case "$MODE" in relay) COMPOSE=compose-relay.yaml ;; *) COMPOSE=compose.yaml ;; esac
podman-compose -f $COMPOSE up -d
