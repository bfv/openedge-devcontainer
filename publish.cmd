@echo off
setlocal

if "%~1"=="" (
    echo Usage: %~nx0 ^<version^>
    exit /b 2
)

set "VERSION=%~1"
for /f "tokens=1,2 delims=." %%A in ("%VERSION%") do set "MAJOR_MINOR=%%A.%%B"
if "%MAJOR_MINOR:~-1%"=="." (
    echo Version must contain at least major.minor, for example 12.8.12-3.
    exit /b 2
)

set "DOCKER_HUB_IMAGE=docker.io/devbfvio/openedge-devcontainer:%VERSION%"
set "DOCKER_HUB_GENERIC=docker.io/devbfvio/openedge-devcontainer:%MAJOR_MINOR%"
set "BFV_IMAGE=registry.bfv.io/openedge/devcontainer:%VERSION%"
set "BFV_GENERIC=registry.bfv.io/openedge/devcontainer:%MAJOR_MINOR%"

docker build --tag "%DOCKER_HUB_IMAGE%" .
if errorlevel 1 exit /b %errorlevel%

docker push "%DOCKER_HUB_IMAGE%"
if errorlevel 1 exit /b %errorlevel%

docker tag "%DOCKER_HUB_IMAGE%" "%BFV_IMAGE%"
if errorlevel 1 exit /b %errorlevel%

docker push "%BFV_IMAGE%"
if errorlevel 1 exit /b %errorlevel%

docker tag "%DOCKER_HUB_IMAGE%" "%DOCKER_HUB_GENERIC%"
if errorlevel 1 exit /b %errorlevel%

docker push "%DOCKER_HUB_GENERIC%"
if errorlevel 1 exit /b %errorlevel%

docker tag "%BFV_IMAGE%" "%BFV_GENERIC%"
if errorlevel 1 exit /b %errorlevel%

docker push "%BFV_GENERIC%"
if errorlevel 1 exit /b %errorlevel%

endlocal