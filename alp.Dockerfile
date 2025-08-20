FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["TodoApi.csproj", "."]
RUN dotnet restore "TodoApi.csproj"
COPY . .
RUN dotnet publish "TodoApi.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app
RUN apk update \
  && apk add --no-cache curl tar bash shadow sudo strace \
  && mkdir /opt/datadog \
  && TRACER_VERSION="3.6.1" \
  && curl -L https://github.com/Datadog/dd-trace-dotnet/releases/download/v${TRACER_VERSION}/datadog-dotnet-apm-${TRACER_VERSION}-musl.tar.gz \
  | tar xzf - -C /opt/datadog

COPY --from=build /app/publish . 

ENV ASPNETCORE_ENVIRONMENT=Development
ENV CORECLR_ENABLE_PROFILING=1
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so
ENV DD_INTEGRATIONS=/opt/datadog/integrations.json
ENV DD_DOTNET_TRACER_HOME=/opt/datadog
ENV DD_LOGS_INJECTION=true
ENV DD_RUNTIME_METRICS_ENABLED="true"
ENV DD_DBM_PROPAGATION_MODE=full
ENV DD_RUNTIME_METRICS_ENABLED=true
ENV DD_PROFILING_ALLOCATION_ENABLED=true
ENV DD_PROFILING_ENABLED=1
ENV DD_PROFILING_GC_ENABLED=true
ENV DD_PROFILING_HEAP_ENABLED=true
ENV DD_PROFILING_WALLTIME_ENABLED=true
ENV DD_PROFILING_EXCEPTION_ENABLED=true
#ENV LD_PRELOAD=/opt/datadog/continuousprofiler/Datadog.Linux.ApiWrapper.x64.so

EXPOSE 8080

ENTRYPOINT ["/cws-instrumentation-volume/cws-instrumentation", "trace", "--verbose", "--", "dotnet", "TodoApi.dll"]
