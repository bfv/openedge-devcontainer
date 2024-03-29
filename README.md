# openedge-devcontainer
VSCode devcontainer for OpenEdge Proof of Concept.

## Setup VSCode
In order for this to work just one extension needs to be installed:

![devcontainers extension](./images/extension.png)

## OpenEdge License
This particular setup uses OpenEdge 12.8. It's in a Docker container hosted on Docker Hub.
This is BYOL (bring your own license) and it this you just need a `progress.cfg` with a Linux 4GL Dev system in it (and whatever the requirement of the containers you add).
Put `progess.cfg` in the `oe-license` folder. If you want to put it in another location, set this in `.devcontainer/.env`

## start
There are two routes to start. 
- Clone this repo locally and start from there
- Clone in a Docker volume (difficult with licenses)

Right now we take the first route, it's easier for demonstrations. 

so, assuming you are IN the directory in which you want to put the clone:
```
git clone https://github.com/bfv/openedge-devcontainer.git .
```

then start VSCode: 
```
vscode . 
```

If you wait a few moments this shows up: <br/>
![choose option "reopen in container"](./images/start-options1.png)

## running OpenEdge in the devcontainer
IN `devcontainer.json` an extra extry have been added:
```
"formulahendry.code-runner"
```
This manifests itself like:<br/>
![run button](./images/run-button-vscode.png)

To check if everything works, on the host:
```
curl http://localhost:8810/web/api/get
curl http://localhost:8810/web/api/customers
```
