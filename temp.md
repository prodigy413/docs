```
mkdir aspnet-test && cd aspnet-test


FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src
RUN dotnet new web -n TestApp -f net11.0
RUN dotnet publish TestApp/TestApp.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:11.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "TestApp.dll"]


docker build -t aspnet-test .


docker run -d --name aspnet-test -p 8080:8080 aspnet-test


curl http://localhost:8080/
```
