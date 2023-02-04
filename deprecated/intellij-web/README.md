## JetBrains IntelliJ Ultimate or Community in a browser

This is a Kubernetes pod with JetBrains IntelliJ Ultimate IDE and projector to run in a browser

## How it works

- Ask user if they want Community or IDEA Ultimate
- JetBrains and code-server IDEs are installed in the image.
- Once the workspace starts, the JetBrains `projector` CLI configures and starts the JetBrains IDE and code-server (VS Code) IDE to run in a browser
- If IDEA Ultimate, run `remote-dev-server.sh` in `/opt/<ide folder>/bin` to create symbolic link to point Gateway to container's JetBrains IDE

## Important notes

- This template uses a Dockerfile.

- You cannot install IDEs in the image into `/home/coder`, as that is overridden by the volume. That is why different projector configurations are done at runtime with the startup script

- Add all IDEs must be in the image, with the `coder` user. Use `chown` of the `/opt` dir to do this.

- See the `startup_script` in the `main.tf` for more details

## Resources

- [JetBrains projector](https://lp.jetbrains.com/projector/)

- [Coder's documentation on migrating from projector to JetBrains Gateway](https://coder.com/docs/v2/latest/ides/gateway)

- [JetBrains product codes for Dockerfile install](https://plugins.jetbrains.com/docs/marketplace/product-codes.html)

- [JetBrains IntelliJ versions](https://www.jetbrains.com/idea/download/other.html)

- [Five required URLs to download JetBrains IDEs in Gateway - search on download.jetbrains.com](https://www.jetbrains.com/help/idea/remote-development-troubleshooting.html#setup)

- [JetBrains point Gateway to container IDE and not download from JetBrains.com](https://www.jetbrains.com/help/idea/remote-development-troubleshooting.html#setup)

- [JetBrains Gateway fully offline mode](https://www.jetbrains.com/help/idea/fully-offline-mode.html)