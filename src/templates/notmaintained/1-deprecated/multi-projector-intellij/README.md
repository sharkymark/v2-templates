## 2 IntelliJ IDEs

This is a Kubernetes pod with multiple instances of JetBrains projector and 2 IntelliJ Community IDEs

## How it works

- IDEs are installed in the image.
- Once the workspace starts, `projector` configures and runs different instances of each IDE for users to connect via web browser.
- `coder_app` allows a user to access running services from the Coder dashboard.

## Important notes

- This template uses a Dockerfile.

- You cannot install IDEs in the image into `/home/coder`, as that is overridden by the volume. That is why different projector configurations are done at runtime with the startup script

- Add all IDEs must be in the image, with the `coder` user. Use `chown` of the `/opt` dir to do this.

- See the `startup_script` in the `main.tf` for more details

- Also see Coder's [templates documentation](https://coder.com/docs/coder-oss/latest/templates) for more details editing templates.
