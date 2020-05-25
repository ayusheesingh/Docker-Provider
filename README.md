# About

This repository contains source code for Azure Monitor for containers Linux and Windows Agent

# Questions?

Feel free to contact engineering team owners in case you have any questions about this repository or project.

# Prerequisites

## Common
1. [Visual Studio Code](https://code.visualstudio.com/) for authoring
2. [Go lang](https://golang.org/) for building go code

## Linux
3. Ubuntu machine Ubuntu 14.04 to build Linux Agent
4. [Docker](https://docs.docker.com/engine/install/ubuntu/) to build the docker image for Linux Agent

## Windows
5. Windows 10 Professional machine to build  Windows Agent
6. [Dokcer for Windows](https://docs.docker.com/docker-for-windows/) to build docker image for Windows Agent
7. [.NET Core SDK](https://dotnet.microsoft.com/download) to build the Windows Agent code
8. [gcc for windows](https://github.com/jmeubank/tdm-gcc/releases/download/v9.2.0-tdm64-1/tdm64-gcc-9.2.0.exe) to build go code


# Repo structure

The general directory structure is:

```
├── build/                            - files to related to  compile and build the code
│   ├── linux/                         - Makefiles and installer files for the Docker Provider
│   │   ├── docker.version             - docker provider version
│   │   ├── Makefile                   - Makefile to build docker provider code
│   │   ├── Makefle.common             - dependency common file for Makefile
│   │   ├── configure                  - configure file to determine provider configuration
│   │   ├── installer                  - files related to installer
|   |   |   |── bundle/                - shell scripts to create shell bundle
|   |   |   |── conf/                  - plugin configuration files
|   |   |   |── datafiles/             - data files for the installer
|   |   |   |── scripts/               - data files for the installer
|   |   |   |── InstallBuilder/        - python script files for the install builder
│   ├── windows/                       - scripts to build the .net and go code
|   |   |── build.ps1/                 - powershell script to build .net and go lang code and copy the files to omsagentwindows directory
├── alerts/                            - alert queries
├── kubernetes/                        - files related to Linux and Windows Agent for Kubernetes
│   ├── linux/                         - scripts to build the Docker image for Linux Agent
│   │   ├── DockerFile                 - DockerFile for Linux Agent Container Image
│   │   ├── main.sh                    - Linux Agent container entry point
│   │   ├── setup.sh                   - setup file for Linux Agent Container Image
│   │   ├── acrprodnamespace.yaml      - acr woirkflow to push the Linux Agent Container Image
│   │   ├── defaultpromenvvariables    - default environment variables for Prometheus scraping
│   │   ├── defaultpromenvvariables-rs - cluster level default environment variables for Prometheus scraping
│   ├── windows/                       - scripts to build the Docker image for Windows Agent
│   │   ├── acrWorkFlows/              - acr work flows for the Windows Agent container image
│   │   ├── baseimage/                 - windowsservercore base image for the windows agent container
│   │   ├── CertificateGenerator/      - .NET code to create self-signed certificate register with OMS
│   │   ├── fluent/                    - fluent heartbeat plugin code
│   │   ├── fluent-bit/                - fluent-bit plugin code for oms output plugin code
│   │   ├── scripts/                   - scripts for livenessprobe, filesystemwatcher and config parsers etc.
│   │   ├── omsagentwindows/           - out_oms conf file. Build compressed certificate generator  binaries and out_oms.so file will be copied to here
│   │   ├── DockerFile                 - DockerFile for Windows Agent Container Image
│   │   ├── main.ps1                   - Windows Agent container entry point
│   │   ├── setup.ps1                  - setup file for Windows Agent Container Image
│   ├── .../                           - yamls and configuration files to install the Azure Monitor for containers on K8s cluster(s)
├── scripts/                           - scripts for onboarding, troubleshooting and preview scripts related to Azure Monitor for containers
│   ├── troubleshoot/                  - scripts for troubleshooting of Azure Monitor for containers onboarding issues
│   ├── onboarding/                    - scripts related to Azure Monitor for containers onboarding for non-AKS and preview AKS features
├── source/                            - source code
│   ├── code/                          - source code
│   │   ├── go/                        - plugins code in go
│   │   ├── plugin/                    - plugins code inr ruby
│   │   |   ├── health/                - code for health feature
│   │   |   ├── lib/                   - lib for app insights ruby
│   │   ├── toml-parser/               - code for parsing of toml configuration files
│   ├── test/                          - source code for tests
│   │   ├── health/                    - source code for health feature tests
├── !_README.md                        - this file
├── .gitignore                         - git config file with include/exclude file rules
├── LICENSE                            - License file
├── Rakefile                           - Rake file to trigger ruby plugin tests
└── ReleaseNotes.md                    - Release notes for the release of the Azure Monitor for containers agent
```

# Branches

- `ci_prod` branch contains codebase currently in production (or being prepared for release).
- `ci_dev` branch contains version in development.

To contribute: create your private branch off of `ci_dev`, make changes and use pull request to merge back to `ci_dev`.
Pull request must be approved by at least one engineering team members.

# Authoring code

We recommend using [Visual Studio Code](https://code.visualstudio.com/) for authoring.


# Building code

## Linux Agent

### Build Docker Provider Shell Bundle

1. Begin by downloading the latest package for Go by running this command, which will pull down the Go package file, and save it to your current working directory

```
sudo curl -O https://storage.googleapis.com/golang/go1.9.1.linux-amd64.tar.gz
```
2. Next, use tar to unpack the package. This command will use the tar tool to open and expand the downloaded file, and creates a folder using the package name, and then moves it to $HOME
```
sudo tar -xvf go1.9.1.linux-amd64.tar.gz
sudo mv go ~
```
3. Set PATH, GOBIN, GOPATH  environment variables
```
export PATH=$PATH:$HOME/go/bin
export GOBIN=$HOME/go/bin
export GOPATH=~/Docker-Provider/source/code/go #Set this based on your repo path
```
4. Install glide to manage the go dependencies
```
sudo chmod 777 ~/go/bin #Required to get permissions to create glide executable
curl https://glide.sh/get | sh
cd ~/Docker-Provider/source/code/go/src/plugins #cd <path to go src>
glide init
glide update
glide install
```
> Note: If glide init fails with [ERROR] Cowardly refusing to overwrite existing YAML, you can ignore this error if you havent added any new dependecy else delete glide.yaml and re-run the glide init command to create glide.yaml.

you can ignore [ERROR] Cowardly refusing to overwrite existing YAML  for glide init.
5.  Build the code  with below commands

```
cd ~/Docker-Provider/build
./configure --enable-ulinux
make
```
6. If build successful, you should see docker-cimprov-x.x.x-x.universal.x86_64.sh under ~/Docker-Provider/target/Linux_ULINUX_1.0_x64_64_Release/
  > Note: x.x.x-x is the version of the docker provider which is determined from version info in docker.version file

### Build Docker Image

1.  Navigate to below directory to build the docker image
  ```
  cd ~/Docker-Provider/kubernetes/linux/
  ```
2. Make sure the latest docker-cimprov-x.x.x-x.universal.x86_64.sh file location updated in setup.sh
 > Note: x.x.x-x is the version of the docker provider which is determined from version info in docker.version file
3. Build the Docker image via below command
 ```
   docker build -t  <repo>:<imagetag> .
```
4. Push the Docker image to docker repo

## Windows Agent
> Note: To build the Windows Agent Image, you will need Windows 10 Pro or higher machine with Docker for Windows
### Build Certificate Generator Source code and Out OMS Go plugin code
1. Install .Net Core SDK 2.2 or higher from https://dotnet.microsoft.com/download
2. Install go if you havent installed already.
  ```
  cd  %userprofile%
  mkdir go
  cd  %userprofile%\go
  curl -LO https://dl.google.com/go/go1.14.3.windows-amd64.msi
  # install go. default will get installed %SYSTEMDRIVE%\go
  msiexec /i %userprofile%\go\go1.14.3.windows-amd64.msi
  ```
2. Set and Update required PATH and GOPATH environment variables based on the Go bin and repo path
```
set PATH=%PATH%;%SYSTEMDRIVE%\go\bin
set GOPATH=%userprofile%\Docker-Provider\source\code\go #Set this based on your repo path
```
> Note: If you want set these environment variables permanently, you can use setx command instead of set command
3. Download glide to manage the go dependencies. Skip this test if you have glide already on your windows dev/build machine
```
cd  %userprofile%
mkdir glide
curl -LO https://github.com/Masterminds/glide/releases/download/v0.13.3/glide-v0.13.3-windows-amd64.zip
# extract zip file
tar -xf glide-v0.13.3-windows-amd64.zip
cd  %userprofile%\glide\windows-amd64
# update path environment variable with glide.exe path
set PATH=%PATH%;%userprofile%\glide\windows-amd64
```
4. Navigate to go plugin code  and update go dependencies
```
cd  %userprofile%\Docker-Provider\source\code\go\src\plugins # this based on your repo path
glide init
glide update
glide install
```
5. Install [gcc for windows](https://github.com/jmeubank/tdm-gcc/releases/download/v9.2.0-tdm64-1/tdm64-gcc-9.2.0.exe) to build go code if you havent installed
5. Build Certificate generator source code in .NET and Out OMS Plugin code in Go lang  by running these commands in CMD shell
```
cd %userprofile%\Docker-Provider\build\windows # based on your repo path
powershell # switch to powershell from cmd
.\build.ps1 # trigger build and publish
```
### Build Docker Image

1.  Navigate to below directory to build the docker image
```
  cd %userprofile%\Docker-Provider\kubernetes\windows # based on your repo path
```
2. Build the Docker image via below command
```
   docker build -t  <repo>:<imagetag> .
```
3. Push the Docker image to docker repo

# Update Kubernetes yamls

Navigate to Kubernetes directory and update the yamls with latest docker image of Linux and Windows Agent and other relevant updates.