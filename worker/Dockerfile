# Pinned .NET 7 SDK for compilation
FROM --platform=${BUILDPLATFORM} mcr.microsoft.com/dotnet/sdk:7.0.410 AS build
ARG TARGETPLATFORM
ARG TARGETARCH
ARG BUILDPLATFORM
RUN echo "Running on $BUILDPLATFORM, building for $TARGETPLATFORM"

WORKDIR /source
COPY *.csproj .
RUN dotnet restore -a $TARGETARCH

COPY . .
RUN dotnet publish -c release -o /app -a $TARGETARCH --self-contained false --no-restore

# Pinned .NET 7 Runtime for minimal attack surface
FROM mcr.microsoft.com/dotnet/runtime:7.0.20 AS final

# Create dedicated non-root user
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -s /sbin/nologin -d /app appuser

WORKDIR /app
COPY --from=build /app .
RUN chown -R appuser:appuser /app

USER appuser

ENTRYPOINT ["dotnet", "Worker.dll"]
