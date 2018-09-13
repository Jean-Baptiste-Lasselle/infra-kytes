FROM mongo:latest
ADD replicaset-health-check .
RUN chmod +x ./replicaset-health-check
ADD create-replicaset .
RUN chmod +x ./create-replicaset
HEALTH_CHECK --retry 3 --interval 1 CMD ./replicaset-health-check
CMD ["./create-replicaset"]
