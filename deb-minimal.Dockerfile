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
        sudo \
        bash \
        strace \
        ca-certificates \
    && curl -LO https://github.com/DataDog/dd-trace-dotnet/releases/download/v${TRACER_VERSION}/datadog-dotnet-apm_${TRACER_VERSION}_amd64.deb \
    && dpkg -i ./datadog-dotnet-apm_${TRACER_VERSION}_amd64.deb \
    && rm ./datadog-dotnet-apm_${TRACER_VERSION}_amd64.deb \
    && apt-get clean \
    && apt-get autoremove -y 
    
# Copy app and Datadog tracer
COPY --from=build /app/publish . 

# Datadog environment variables
ENV ASPNETCORE_ENVIRONMENT=Development

EXPOSE 8080

ENTRYPOINT ["/cws-instrumentation-volume/cws-instrumentation", "trace", "--verbose", "--", "dotnet", "TodoApi.dll"]
