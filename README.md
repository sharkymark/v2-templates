# v2-templates

##### Description
These are Coder v2 templates that have been customized for demonstrations

##### Last updated

8-31-22 mark@coder.com
1. added a PhpStorm template with the xDebug extension

8-29-22 mark@coder.com
1. adjusted Docker template entrypoint 
1. removed code-server release input variable from most templates
1. adjust Docker Terraform provider version to `2.20.2`
1. updated `pod-with-rubymine` template adding `mkdir -p ~/.ssh` for `git clone` to work; changed `rubyonrails` app port to `3001` to not conflict with a `coder server` running on `3000`

8-28-22 mark@coder.com
1. Created a Kubernetes pod template that prompts the user to install Jupyter Lab or Jupyter Notebook IDE.
1. There is removed TF code in a separate file. It appears I found a bug with `coder_metadata` working with Kubernetes pods. [Issue 3721](https://github.com/coder/coder/issues/3721)

8-25-22 mark@coder.com
1. kubernetes pod templates that put the jetbrains IDE and projector in the image
1. Incl. IntelliJ IDEA Ultimate [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/idea-ult-vscode) | [DockerHub](https://hub.docker.com/repository/docker/marktmilligan/idea-vscode)
1. Inc. IntelliJ IDEA Community [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/idea-ult-comm-vscode) | [DockerHub](https://hub.docker.com/repository/docker/marktmilligan/idea-comm-vscode)
1. Incl. PyCharm Professional [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/pycharm-pro-vscode) | [DockerHub](https://hub.docker.com/repository/docker/marktmilligan/pycharm-pro-vscode)
1. Incl. PyCharm Community [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/pycharm-comm-vscode) | [DockerHub](https://hub.docker.com/repository/docker/marktmilligan/pycharm-comm-vscode)

8-23-22 mark@coder.com
1. aws and azure templates can only run with users other than admin@coder.com (will be fixed in a future release)

8-20-22 mark@coder.com
1. updated Coder Terraform provider to 0.4.9
1. aws templates have temporary fix - use `ubuntu` user and do not create a user in the VM to resolve `connecting` stuck status [Filed issue #3611](https://github.com/coder/coder/issues/3611)

8-13-22 mark@coder.com 
1. bug: added `mkdir -p ~/.ssh` before `ssh-keyscan` and `git clone`
1. updated kubernetes, docker and coder Terraform provider releases
1. removed `2>&1 | tee <filename.log>` logging since `/tmp/coder-startup-script.log` captures it now
1. add a jupyter docker template that lets the user decide if they want Jupyter Notebook or Jupyter Lab

##### Goals
1. Be able to demo a Kubernetes pod as a workspace
1. Be able to add code-server (VS Code in a browser) in a workspace
1. Be able to demonstrate JetBrains Gateway
1. Show a workspace as a GCP VM, with dockerd inside
1. Show JetBrains projector (JetBrains in a browser) in a workspace - IntelliJ, PyCharm, GoLand
1. Show multiple JetBrains IDE projects with projector
1. Show Eclipse IDE in a VNC workspace
1. Be able to demonstrate data science tools like Jupyter Notebook, Jupyter Lab, Airflow, RStudio
1. Be able to show code-server and JetBrains IDEs in workspaces running on a dockerd