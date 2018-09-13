FROM mongo:latest

HEALTH_CHECK --retry 3 --interval 1 CMD replicaset-health-check
