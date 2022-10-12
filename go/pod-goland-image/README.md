## GoLand IDE

This is a Kubernetes pod with JetBrains projector to access the GoLand IDE through a browser

## How it works

- GoLand is installed in the image.
- Once the workspace starts, `projector` is installed, configures and runs the IDE for users to connect via web browser.
- `coder_app` allows a user to access running services from the Coder dashboard.

## Important notes

- This template uses a [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/go/goland-chmod).

- You cannot install IDEs in the image into `/home/coder`, as that is overridden by the volume. That is why different projector configurations are done at runtime with the startup script

- Add all IDEs must be in the image, with the `coder` user. Use `chown` of the `/opt` dir to do this.

- See the `startup_script` in the `main.tf` for more details

- Also see Coder's [templates documentation](https://coder.com/docs/coder-oss/latest/templates) for more details editing templates.
