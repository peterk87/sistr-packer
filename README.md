Building VMs with packer
========================

This guide describes how to set up your workstation to build VM images of SISTR with [packer](https://packer.io).


General Requirements
--------------------

You're required to install a few different pieces of software on your machine before you can get started:

1. [packer](https://packer.io) (install guide: <https://packer.io/docs/installation.html>)
2. [VirtualBox](https://www.virtualbox.org) (install guide: <https://www.virtualbox.org/wiki/Linux_Downloads>)


Building the VM
---------------

*NOTE: You can only build the VM in a GUI/non-headless OS environment (e.g. your local machine running Ubuntu). It is not possible at this time to build the VM on a headless server.*

You can build the VM once you've got the prerequisites installed. From the `packer/` directory in the root of the project folder, run:

    packer build template.json

This will:

1. Download a CentOS 7.1 ISO,
2. Run an automated CentOS kickstart script in VirtualBox (VirtualBox should pop up on your screen),
3. Install the VirtualBox tools,
4. Run the customization scripts (importantly running `sistr.sh`),
5. Package the customized VirtualBox image as a VirtualBox appliance (found in `packer/output-virtualbox-iso`).


Using the VM
------------

You can import the `.ovf` file in `packer/output-virtualbox-iso` into VirtualBox by double clicking it, or running something like:

```bash
cd output-virtualbox-iso
xdg-open packer-virtualbox-iso*.ovf
```


### Ports

By default, the appliance is set up using NAT for networking. 
The appliance is configured to do port forwarding via `localhost` such that you can access the SISTR HTTP API through <http://localhost:44448/api> or the SISTR web app by navigating to <http://localhost:44449/sistr>

You can SSH into the virtual machine with:

```bash
ssh -p 42222 vagrant@localhost
```

The default password is `vagrant`.

### Log files

We've configured packer to build us an image of CentOS 7.1, which has migrated to [systemd](http://www.freedesktop.org/wiki/Software/systemd/).

SISTR log files are located in `/home/sistr/sistr_backend/tmp/*.log`
