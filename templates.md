# Coder OSS (v2) templates

These are Coder OSS templates (Terraform scripts) that have been customized for demonstrations

##### Last updated

9-17-22 mark@coder.com
1. updated `pod-with-code-server` to include `coder_metadata` resource to surface helpful data like image, repo cloned, cpu, memory, disk, volume.

[Changelog](changelog.md)

# Workspaces as Docker containers
> A Docker daemon must be running on the same host as the `coder server`. e.g., if this is a remote VM, the Docker engine must be installed. If a local computer, Docker Desktop must be running.
- With [code-server IDE](./docker-code-server/main.tf) and demonstrates prompting the user for image, repo, and VS Code extension.
- With [GoLand IDE](./docker-with-goland/main.tf) 
- With [IntelliJ IDE](./docker-with-intellij/main.tf) 
- With [Jupyter IDE](./docker-with-intellij/main.tf) and an input variable prompts the user to decide if Notebook or Lab should be started.
- With [PyCharm IDE](./docker-with-pycharm/main.tf) 
- With [VNC](./docker-with-vnc/main.tf) 

# Workspaces as public cloud VMs
> The pertinent public cloud CLI must be installed on the same host as the `coder server`. This provides Coder with an authentication mechanism to provision compute in the cloud.
- With [AWS Linux VM](./aws-linux-vm/main.tf) 
- With [AWS Spot Linux VM](./aws-spot/main.tf) which take advantage of [unused EC2 capacity in the AWS cloud](https://aws.amazon.com/ec2/spot/) and can provide up to 90% cost savings over dedicated VMs.
- With [Google Cloud VM](./gcp-ubuntu-docker/main.tf) which includes Docker in the VM to demonstrate how developers can use Docker in their workspace. e.g., `docker-compose` additional containers.
- With [Microsoft Azure Linux VM](./azure-linux/main.tf)

# Workspaces with JetBrains IDEs
> JetBrains no longer supports [`projector`](https://jetbrains.github.io/projector-client/mkdocs/latest/ij_user_guide/jetbrains/), their OSS project to run JetBrains IDEs in a browser. JetBrains encourages developers to use [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/), client software to communicate with a Coder workspace. We provide `projector` example templates here for demonstration purposes.
- With IntelliJ [Community](./pod-w-idea-comm-vsc-img/main.tf) and [Ultimate](./pod-w-idea-ult-vsc-img/main.tf) where IDE is baked into the image and the `projector` CLI creates a config.
- With PyCharm [Community](./pod-w-pycharm-comm-vsc-img/main.tf) and [Professional](./pod-w-pycharm-pro-vsc-img/main.tf) where IDE is baked into the image and the `projector` CLI creates a config.
- With IntelliJ [Community](./multi-projector-intellij/main.tf) and PyCharm [Community](./multi-projector-pycharm/main.tf) where 2 IDE instances are shown and IDE is baked into the image and the `projector` CLI creates a config. This is a more streamlined way to leverage the `projector config add` then the previous examples.
- With [IntelliJ](./pod-with-intellij/main.tf), [PyCharm](./pod-with-pycharm/main.tf), [GoLand](./pod-with-goland/main.tf), [Rubymine](./pod-with-rubymine/main.tf), and [CLion (and Rust)](./pod-with-clion-rust/main.tf) where the `projector` CLI creates installs the IDE specified by a user's input variable in the template. This stores the IDE in the PVC.

# Workspaces with Data Science IDEs
- With [Airflow](./pod-with-airflow-pforward/main.tf) where IDE is accessible with `coder port-forward`
- With [Jupiter] (./pod-with-airflow-pforward/main.tf) where IDE is accessible from a path and a `coder_app` icon. This template prompts the user to choose whether to start Jupyter Notebook or Lab.
- With [RStudio](./pod-with-rstudio-port-forward-only/main.tf) where IDE is accessible with `coder port-forward`

# Workspaces with VNC
- With [VNC](./pod-with-vnc/main.tf) where VNC can act as a virtual desktop into the Kubernetes pod workspace container.
