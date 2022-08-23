# v2-templates

##### Description
These are Coder v2 templates that have been customized for demonstrations

##### Last updated

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