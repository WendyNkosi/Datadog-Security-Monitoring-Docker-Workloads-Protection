FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["TodoApi.csproj", "."]
RUN dotnet restore "TodoApi.csproj"
COPY . .
RUN dotnet publish "TodoApi.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
# Install dependencies and Datadog .NET Tracer
RUN TRACER_VERSION=3.10.0 \
    && apt-get update \
    && apt-get --no-install-recommends install -y \
        build-essential \
        jq \
        wget \
        curl \
        ca-certificates \
    && curl -LO https://github.com/DataDog/dd-trace-dotnet/releases/download/v${TRACER_VERSION}/datadog-dotnet-apm_${TRACER_VERSION}_amd64.deb \
    && dpkg -i ./datadog-dotnet-apm_${TRACER_VERSION}_amd64.deb \
    && rm ./datadog-dotnet-apm_${TRACER_VERSION}_amd64.deb \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
# Copy app and Datadog tracer
COPY --from=build /app/publish . 

# Datadog environment variables
ENV ASPNETCORE_ENVIRONMENT=Development
# Datadog environment variables
ENV CORECLR_ENABLE_PROFILING=1
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so
ENV DD_INTEGRATIONS=/opt/datadog/integrations.json
ENV LD_PRELOAD=/opt/datadog/continuousprofiler/Datadog.Linux.ApiWrapper.x64.so
ENV DD_DOTNET_TRACER_HOME=/opt/datadog
ENV DD_LOGS_INJECTION=true

ENV DD_RUNTIME_METRICS_ENABLED=true
ENV DD_PROFILING_ALLOCATION_ENABLED=true
ENV DD_PROFILING_ENABLED=1
ENV DD_PROFILING_GC_ENABLED=true
ENV DD_PROFILING_HEAP_ENABLED=true
ENV DD_PROFILING_WALLTIME_ENABLED=true

EXPOSE 8080

ENTRYPOINT ["/cws-instrumentation-volume/cws-instrumentation", "trace", "--verbose", "--", "dotnet", "TodoApi.dll"]
