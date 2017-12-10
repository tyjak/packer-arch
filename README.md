CAUTION : WORK IN PROGRESS, NOT FUNCTIONAL

Packer VirtualBox Arch
======================

DISCLAIMER: THIS IS A MODIFIED VERSION OF [PACKER ARCH](https://github.com/elasticdog/packer-arch) BY AARON BULL SCHAEFER

Packer VirtualBox Arch is a bare bones [Packer](https://www.packer.io/) template and
installation script that can be used to generate a [Vagrant](https://www.vagrantup.com/)
full box for [Arch Linux](https://www.archlinux.org/). The template works
with the default VirtualBox provider. This will deploy a full Archlinux box
with feature present in my [ansible archlinux installation](https://github.com/tyjak/ansible-archlinux).

Overview
--------

My goal was to have my current config easily deploy in a virtual box:

* 64-bit
* 60 GB disk
* 1024 MB memory
* Only a single /root partition (ext4)
* No swap
* Includes the `base` and `base-devel` package groups
* OpenSSH is also installed and enabled on boot

The installation script follows the
[official installation guide](https://wiki.archlinux.org/index.php/Installation_Guide)
pretty closely, with a few tweaks to ensure functionality within a VM. Beyond
that, the only customizations to the machine are related to the vagrant user
and the steps recommended for any base box.

Usage
-----

### VirtualBox Provider

Assuming that you already have Packer,
[VirtualBox](https://www.virtualbox.org/), and Vagrant installed.

You can customize some defauls var with a json var files lise `myvar.json`:

    {
        "username": "YOUR-LOGIN-NAME",
        "password": "YOUR-PASSWORD-NAME",
        "pubkey": "YOUR-SSH-PUBKEY"
    }

Now you should be good to clone this repo and go:

    $ git clone https://github.com/elasticdog/packer-arch.git
    $ cd packer-arch/
    $ packer build -var-file=myvar.json arch-template.json

Then you can import the generated box into Vagrant:

    $ vagrant box add arch output/packer_arch_virtualbox.box


### wrapacker

DISCLAIMER : this was not tested

For convenience, there is a wrapper script named `wrapacker` that will run the
appropriate `packer build` command for you that will also automatically ensure
the latest ISO download URL and optionally use a mirror from a provided country
code in order to build the final box.

    $ wrapacker --country US --dry-run

See the `--help` flag for additional details.


License
-------

Packer Arch is provided under the terms of the
[ISC License](https://en.wikipedia.org/wiki/ISC_license).

Copyright &copy; 2013&#8211;2017, [David Foucher](mailto:dev@tyjak.net) 
based on the excellent work of Aaron Bull Schaefer.

Copyright &copy; 2013&#8211;2017, [Aaron Bull Schaefer](mailto:aaron@elasticdog.com).
