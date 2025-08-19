FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["TodoApi.csproj", "."]
RUN dotnet restore "TodoApi.csproj"
COPY . .
RUN dotnet publish "TodoApi.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish . 

# Datadog environment variables
EXPOSE 8080

ENTRYPOINT ["/cws-instrumentation-volume/cws-instrumentation", "trace", "--verbose", "--", "dotnet", "TodoApi.dll"]
