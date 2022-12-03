---
name: Develop in Windows and Visual Studio on Google Cloud VM
description: Get started with Windows and Visual Studio development on Google Cloud.
tags: [cloud, gcp, windows]
---

# Visual Studio IDE on a Windows VM in Google Cloud

### Apps included
1. A web-based terminal
1. Microsoft Windows Server 2022 or 2019 (user-prompted)
1. Microsoft Visual Studio 2022 or 2019 Community Edition (user-prompted)

### Additional bash scripting
1. Prompt user for Google Cloud region e.g., us-central1-a
1. Prompt user for Google Cloud machine type e.g., e2.medium
1. Enable RDP
1. Configure Chocolatey to run in non-interactive mode
1. Install Microsoft Visual Studio with Chocolatey

### Known limitations and required steps
1. You may get an 'unable to connect' message initially - hang tight, it should go away and you will see Terminal
1. Add the Coder CLI to your local machine, login and start a tunnel for the RDP port in the workspace

```sh
coder login <your Coder deployment access URL>
coder tunnel <workspace-name> --tcp 3301:3389
```

1. [Microsoft's RDP client](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-clients) must be installed on the local machine to access the workspace. CoRD RDP client did not connect.
1. Create a new configuration in Microsoft's RDP client, adding 127.0.0.1:3301 as the host, `Administrator` as the username and the password `coderRDP!` and connect.

## Additional Notes
1. Run this Google Cloud CLI command to see the Windows images `gcloud compute images list --project=windows-cloud`
1. `coder_startup_script.log` is located in `C:\Windows\Temp`
1. Installing Visual Studio will take several minutes, so hang tight.

## Future work
1. Test additional RDP thick clients like CoRD
1. Test browser-based RDP clients like [Apache Guacamole](https://guacamole.apache.org/)


### Resources
[Microsoft Remote Desktop (macOS)](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466)

[Chocolatey package manager for Windows](https://chocolatey.org/)

[Microsoft Visual Studio Releases](https://learn.microsoft.com/en-us/visualstudio/productinfo/vs-roadmap)

[Microsoft Visual Studio Community home page](https://visualstudio.microsoft.com/vs/community/)

[Getting Started with Visual Studio](https://visualstudio.microsoft.com/vs/getting-started/)

[Google Cloud Regions](https://cloud.google.com/about/locations)

[Google Cloud Machine Types](https://cloud.google.com/compute/docs/machine-resource)

[Google Cloud e2 Machine Types](https://cloud.google.com/compute/docs/general-purpose-machines#e2_machine_types)

[sharkymark's v2 templates](https://github.com/sharkymark/v2-templates)

[Microsoft technical overview of the RDP protocol](https://learn.microsoft.com/en-us/troubleshoot/windows-server/remote/understanding-remote-desktop-protocol)

[RDP on Wikipedia](https://en.wikipedia.org/wiki/Remote_Desktop_Protocol)


