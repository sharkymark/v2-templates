---
name: Develop in a Ruby on Rails container in a Kubernetes pod
description: The goal is to enable code-server and JetBrains IDEs, and Ruby, and Ruby on Rails
tags: [cloud, kubernetes]
---

# Container for Ruby on Rails development

### Apps included
1. A web-based terminal
1. code-server IDE
1. JetBrains Rubymine IDE (browser)
1. JetBrains Rubymine IDE (locally installed Gateway)

### Included in the container image
1. Ruby 2.6.6, 2.7.2
1. bundler gem
1. Ruby on Rails 7
1. [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/rbenv/rubymine)

### Additional user inputs and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for CPU, memory, and disk storage
1. Install VS Code Ruby debugger extension from Open-VSX marketplace
1. Start code-server IDE
1. Clone the survey app repo called `rubyonrails`
1. Start an employee survey app as a subdomain on 3002

### Bundler and gems

The template has a `coder_app` for the survey app so needs to bundle the gems during `startup_script` with

```sh
    bundle config set --local path './bundled-gems'
    bundle install
```

The Rails server is also started as a daemon in the `startup_script` with

`rails s -p 3002 -b 0.0.0.0 -d`

### Debugging

If you want to debug the Rails app:

1. First kill the running Rails server that was started in the agent startup_script 

```sh
kill $(lsof -i :3002 -t)
```

2. Create a `launch.json` Debugger configuration

```json
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit:
    // https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for rdebug-ide",
            "type": "Ruby",
            "request": "attach",
            "remoteHost": "127.0.0.1",
            "remotePort": "1234",
            "remoteWorkspaceRoot": "${workspaceRoot}"
        }
    ]
}
```
3. Set a breakpoint in a Rails controller of the repo e.g., `./app/controllers/posts_controller`

```ruby
def index

@posts = Post.user.select("posts.id, posts.user_id, title, text, product, status, notes, users.email, posts.created_at, posts.cached_votes_total, anonymous")
```

4. Open a terminal in the Rails repo directory and start the debugger

```sh
bundle exec rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 1234 -- bin/rails s -p 3002
```
5. Start the new debugger configuration. The rails server will start and open the Rails app in a browser. VS Code will prompt with the port of the running app
6. Step through the code checking out the values


### Resources

[jetbrains rubymine releases](https://data.services.jetbrains.com/products/releases?code=RM)

[bundler config docs](https://bundler.io/v1.12/man/bundle-config.1.html)

[bundler install docs](https://bundler.io/v1.12/man/bundle-install.1.html)

[coder terraform provider docs for script](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/script)