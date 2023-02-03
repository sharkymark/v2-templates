## JetBrains CLion in a browser

This is a Kubernetes pod with JetBrains CLion IDE and projector to run in a browser

## How it works

- JetBrains and code-server IDEs are installed in the image.
- Once the workspace starts, the JetBrains `projector` CLI configures and starts the JetBrains IDE and code-server (VS Code) IDE to run in a browser

## Important notes

- This template uses a Dockerfile.

- You cannot install IDEs in the image into `/home/coder`, as that is overridden by the volume. That is why different projector configurations are done at runtime with the startup script

- Add all IDEs must be in the image, with the `coder` user. Use `chown` of the `/opt` dir to do this.

- See the `startup_script` in the `main.tf` for more details

## Resources

- [JetBrains projector](https://lp.jetbrains.com/projector/)

- [Coder's documentation on migrating from projector to JetBrains Gateway](https://coder.com/docs/v2/latest/ides/gateway)

- [JetBrains product codes for Dockerfile install](https://plugins.jetbrains.com/docs/marketplace/product-codes.html)