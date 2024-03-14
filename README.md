# Coder v2 OSS and v2 Enterprise help

> This repo is no longer actively supported. Use [template examples in the OSS repo](https://github.com/coder/coder/tree/main/examples/templates) and the [registry](https://registry.coder.com)

This is an FAQ, tips and tricks, and best practices to get you going with Coder v2 OSS and v2 Enterprise (paid). If you're looking for an v2 enterprise trial key, fill out this [form](https://coder.com/trial) for a 30-day trial  or you can sign up when creating your admin user after deploying Coder.

> These templates are examples and are not supported. They are meant to show how Coder templates work and there is no service level agreement or support on them.

> *2023-02-03* Any templates in the deprecated directory either do not work or may not work. e.g., [JetBrains no longer supports `projector`](https://lp.jetbrains.com/projector/) their project to run IDEs in a browser. Many of the deprecated templates use `projector` and should be ignored. JetBrains users should use [JetBrains Gateway]() and [our docs explain this in more depth](https://coder.com/docs/v2/latest/ides/gateway).

The [official v2 docs](https://github.com/coder/coder/tree/main/docs) and [template examples](https://github.com/coder/coder/tree/main/examples/templates) are great resources too. Also my colleague [bpmct](https://github.com/bpmct/coder-templates) authors some amazing templates too.

# Easiest way to getting started

The easiest and fastest way to run Coder is from the command line with the `coder` binary.

Download it here

```sh
curl -fsSL https://coder.com/install.sh | sh
```

If you're on macOS and not a fan of `brew` like me, make sure you run this command instead:

```sh
curl -fsSL https://coder.com/install.sh | sh -s -- --method standalone
```

> BTW, the coder binary is also the Coder CLI, which you use to create, push templates, even create, start, stop workspaces, API Key tokens, etc.

You can pass parameters/flags after `coder server` but I have a nice [`coder.yaml`](./standalone-yaml/coder.yaml) to easily tweak settings.

```sh
coder server --config coder.yaml
```

# Videos

Here are [some short videos](videos.md) installing, configuring and using Coder v2. As new features arrive, I add new videos.

# Templates

Use the Docker, Kubernetes, Azure, AWS and Google Cloud templates in this repo to kick start your work. The example templates that ship with v2 are [here](https://github.com/coder/coder/tree/main/examples/templates) and [bpmct](https://github.com/bpmct/coder-templates) has some sweet templates too like podman and nifty AWS VM template that only persists the home volume.

# Template Emoji URLs

Here are several [Emoji URLs](emoji-urls.md) to IDE, programming language, and infrastructure emojis to make your templates pop in the Coder UI.

# Frequently Asked Questions (FAQ)

[Coder's docs](https://github.com/coder/coder/tree/main/docs) are the first place to answers but I compile things that I find are important or recurring. [Here is the FAQ](faq.md).

# API examples

You can find API endpoints from inspecting the UI in your browser tools. [Here are examples](api.md) to get you going.
