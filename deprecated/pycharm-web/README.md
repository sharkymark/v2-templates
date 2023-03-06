## JetBrains PyCharm Professional in a browser

This is a Kubernetes pod with JetBrains PyCharm Professional IDE and projector to run in a browser

## How it works

- PyCharm Professional and code-server IDEs are installed in the image.
- Once the workspace starts, the JetBrains `projector` CLI configures and starts the JetBrains IDE and code-server (VS Code) IDE to run in a browser
- If PyCharm Professional, run `remote-dev-server.sh` in `/opt/<ide folder>/bin` to create symbolic link to point Gateway to container's JetBrains IDE

## Important notes

- JetBrains projector is no supported - use this template at your own risk. Move to JetBrains Gateway

- This template uses [this Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/deprecated/pycharm/pro/Dockerfile)

- You cannot install IDEs in the image into `/home/coder`, as that is overridden by the volume. That is why different projector configurations are done at runtime with the startup script

- Add all IDEs must be in the image, with the `coder` user. Use `chown` of the `/opt` dir to do this.

- See the `startup_script` in the `main.tf` for more details

## Resources

- [JetBrains projector](https://lp.jetbrains.com/projector/)

- [Coder's documentation on migrating from projector to JetBrains Gateway](https://coder.com/docs/v2/latest/ides/gateway)

- [JetBrains product codes for Dockerfile install](https://plugins.jetbrains.com/docs/marketplace/product-codes.html)

- [JetBrains IntelliJ versions](https://www.jetbrains.com/idea/download/other.html)