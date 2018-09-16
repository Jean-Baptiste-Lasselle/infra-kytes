FROM mongo:latest
# ADD replicaset-health-check .
# RUN chmod +x ./replicaset-health-check
ADD create-replicaset .
RUN chmod +x ./create-replicaset
# + ERROR: compose.cli.errors.log_api_error: Dockerfile parse error line 6: Interval "start-period" cannot be less than 1ms
# HEALTHCHECK --interval=1s --timeout=2s --start-period=1ms --retries=3 CMD ./replicaset-health-check
#     --interval=1s (default: 30s)
#     --timeout=2s (default: 30s)
#     --start-period=0s (default: 0s)
#     --retries=3 (default: 3)
# + le boulot de tout bon soudeur en eaux profondes.
CMD ["./create-replicaset"]
