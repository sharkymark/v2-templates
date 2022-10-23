# Changelog

10-23-22 mark@coder.com
1. php, ruby on rails, and phpstorm templates

10-22-22 mark@coder.com
1. Added path to coder_apps of Airflow and RStudio to launch from an icon
1. Hid resources in Azure template
1. Updated Eclipse and VNC templates
    
10-14-22 mark@coder.com 
1. Updated AWS and Azure templates with more current Coder provider and additional meta_data; also installing latest code-server/VS Code versus as an input parameter

10-12-22 mark@coder.com
1. added `coder_metadata` resource to pycharm and intellij - showing pod security context, cpu and memory limits and requests, image, etc.

10-3-22 mark@coder.com
1. moved some templates to a new dir `the-archives` which are using older techniques or not as often used. Goal is to free up the `v2-templates` dir for primary templates
2. added new JetBrains templates using the `chusr` approach of granting `coder` user as the owner of the `/opt` dir so the projector CLI can just create configs and reference the IDE installed in the image versus the `startup_script`


10-2-22 mark@coder.com
1. updated pod-with-code-server to remove image pull policy always and move clone steps above code-server install and start

9-3-22 mark@coder.com
1. updated `pod-with-code-server` to prompt for namespace and added bash logic to install `latest` or a specific release of `code-server` VS Code IDE


9-2-22 mark@coder.com
1. new multi IntelliJ & PyCharm templates `multi-projector-intellij` and `multi-projector-pycharm` - `chmod` technique of `projector config add` - thank you [bpmct](https://github.com/bpmct)

9-1-22 mark@coder.com
1. removed # symbol from `pod-with-intellij-projects` template which causes `Application not found` error on IDE launch

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