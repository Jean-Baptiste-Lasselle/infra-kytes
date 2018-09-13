FROM mongo:latest
ADD replicaset-health-check .
RUN chmod +x ./replicaset-health-check
ADD create-replicaset .
RUN chmod +x ./create-replicaset
HEALTH_CHECK --interval=1s --timeout=2s --start-period=0s --retries=3 CMD ./replicaset-health-check
#     --interval=1s (default: 30s)
#     --timeout=2s (default: 30s)
#     --start-period=0s (default: 0s)
#     --retries=3 (default: 3)
CMD ["./create-replicaset"]
