## 2 PyCharm IDEs

This is a Kubernetes pod with multiple instances of JetBrains projector and 2 PyCharm Community IDEs

## How it works

- IDEs are installed in the image.
- Once the workspace starts, `projector` configures and runs different instances of each IDE for users to connect via web browser.
- `coder_app` allows a user to access running services from the Coder dashboard.

## Important notes

- This template uses a Dockerfile. You can build your own from [my example](https://github.com/sharkymark/dockerfiles/tree/main/multi-jetbrains/multi-pycharm/Dockerfile) and change it [in the template](https://github.com/sharkymark/v2-templates/tree/main/multi-projector-pycharm)

- You cannot install IDEs in the image into `/home/coder`, as that is overridden by the volume. That is why different projector configurations are done at runtime with the startup script

- Add all IDEs must be in the image, with the `coder` user. Use `chown` of the `/opt` dir to do this.

  - To add a new IDE, e.g. Goland, reference [enterprise-images](https://github.com/coder/enterprise-images/blob/91bf78a9dc6bb18a205f475a141987de4f1eae9e/images/goland/Dockerfile.ubuntu) and add to the Dockerfile

  - Build and push the image

  - Add a new projector config to the startup_script in the template:

    ```sh
    /home/coder/.local/bin/projector config add goland /opt/goland --force --use-separate-config --port 9005 --hostname localhost
    /home/coder/.local/bin/projector run goland &
    ```

  - Add a new coder_app to access the resource

    ```hcl
    resource "coder_app" "goland" {
    agent_id = coder_agent.dev.id
    name     = "goland"
    icon     = "/icon/goland.svg"
    url      = "http://localhost:9005"
    }
    ```

- Also see Coder's [templates documentation](https://coder.com/docs/coder-oss/latest/templates) for more details editing templates.
