# Datadog-Security-Monitoring-Docker-Workloads-Protection

## **Steps to follow:**

- **first run the dd-agent**<br>
`docker run -d --name dd-agent   --cgroupns host   --pid host   --security-opt apparmor:unconfined   --cap-add SYS_ADMIN   --cap-add SYS_RESOURCE   --cap-add SYS_PTRACE   --cap-add NET_ADMIN   --cap-add NET_BROADCAST   --cap-add NET_RAW   --cap-add IPC_LOCK   --cap-add CHOWN   -v /var/run/docker.sock:/var/run/docker.sock:ro   -v /proc/:/host/proc/:ro   -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro   -v /etc/passwd:/etc/passwd:ro   -v /etc/group:/etc/group:ro   -v /:/host/root:ro   -v /sys/kernel/debug:/sys/kernel/debug   -v /etc/os-release:/etc/os-release   -e DD_COMPLIANCE_CONFIG_ENABLED=true   -e DD_COMPLIANCE_CONFIG_HOST_BENCHMARKS_ENABLED=true   -e DD_RUNTIME_SECURITY_CONFIG_ENABLED=true   -e DD_RUNTIME_SECURITY_CONFIG_REMOTE_CONFIGURATION_ENABLED=true   -e HOST_ROOT=/host/root   -e DD_API_KEY=<your dd-api-key>   gcr.io/datadoghq/agent:7`


- **build the application image** <br>
`docker build -f alp.Dockerfile -t todo-api-alp .`

- **create the cws volume**<br>
`docker run --rm   --name cws-instrumentation-init   -v cws-instrumentation:/cws-instrumentation-volume   -u 0   datadog/cws-instrumentation:7.63.1   /cws-instrumentation setup --cws-volume-mount /cws-instrumentation-volume`


- **run the application container**<br>
`docker run -d --name todo-api   --link dd-agent:dd-agent   --cap-add SYS_PTRACE   -v cws-instrumentation:/cws-instrumentation-volume:ro   -e DD_AGENT_HOST=dd-agent   -e DD_TRACE_AGENT_PORT=8126   -e DD_RUNTIME_SECURITY_CONFIG_ENABLED=true   -e DD_RUNTIME_SECURITY_CONFIG_REMOTE_CONFIGURATION_ENABLED=true   -e DD_API_KEY=<your dd-api-key> todo-api  /cws-instrumentation-volume/cws-instrumentation trace -- dotnet TodoApi.dll`


- **exec into container and trigger an event**<br>
`docker exec -it todo-api-deb-traced bash`<br>
`touch /tmp/myfile.txt && chmod +x /tmp/myfile.txt`<br>
`useradd wendy && passwd wendy`

- **check tracing works when APM is enabled**<br>
`curl -X GET http://localhost:8080/api/healthcheck`

