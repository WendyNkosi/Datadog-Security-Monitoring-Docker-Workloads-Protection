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
  && adduser -D testuser && echo "testuser:Password123!" | chpasswd


COPY --from=build /app/publish . 

ENV ASPNETCORE_ENVIRONMENT=Development

EXPOSE 8080

ENTRYPOINT ["/cws-instrumentation-volume/cws-instrumentation", "trace", "--verbose", "--", "dotnet", "TodoApi.dll"]
