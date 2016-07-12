# Cloudy LBMake

Cloudy **LBMake** (**L**ive **B**uild **Make**) is a tool to build and package the Cloudy distribution. It bootstraps the root filesystem, includes the default packages and automates
the creation of Cloudy live and installation .iso images.

Currently, LBMake supports the i386 and amd64 architectures. To install Cloudy on a device with another architecture (i.e. ARM-based mini-PCs), you may want to check the [*Cloudynitzar*](https://github.com/Clommunity/cloudynitzar "Cloudynitzar at GitHub") tool.


## Prerequisites

On a machine running an up-to-date Debian Jessie operating system, install the required packages:

	sudo apt-get install build-essential live-build imagemagick curl debootstrap git unzip


## Build

Depending on which device you want to install Cloudy, you may choose one of the following build options:

### i386 architecture (32 bits), i586 compatible (default)

The default build process generates 32 bits images for i586 processors (or newer):

	sudo make

The generated images will likely be compatible with most i386-based 32 bits CPUs.

### i386 architecture, i686 compatible + PAE extensions (32 bits)

Most modern 32 bit x86 processors will likely benefit from the i686-pae build flavour:

	sudo make FLAVOUR=686-pae

### amd64 architecture (64 bits)

Most 64 bits x86 processors will likely be compatible and benefit from running the amd64 architecture images:

	sudo make ARCH=amd64 FLAVOUR=amd64

If you are going to install Cloudy on a 64 bits computer, this one is probably your best choice.

## Test

Once the image has been created, you can test the live system  with one of the following commands, depending on the architecture you specified at build time (the default is i386):

	sudo apt-get install qemu

	qemu-system-i386 -m 512 --cdrom devel/live-image-i386.hybrid.iso
	--or--
	qemu-system-x86_64 -m 512 --cdrom devel/live-image-amd64.hybrid.iso

If you have a relatively recent computer, appending `--enable-kvm` should take
advantage of hardware virtualization and make it work much faster. You may want to increase or decrease the amount of RAM memory used by the virtual machine (512 MB).

In order to test the installation and setup of the distro, you can create a
disk image and use it as well:

	qemu-img create -f qcow2 disk.qcow2 4G

	qemu-system-i386 -enable-kvm -cdrom devel/live-image-i386.hybrid.iso -hda disk.qcow2
	--or--
	qemu-system-x86_64 -enable-kvm -cdrom devel/live-image-amd64.hybrid.iso -hda disk.qcow2


## Creating an LXC container

If you prefer to create a container instead of using a live CD image or a complete installation, you can generate a container image in your system by running:

	sudo make container
	--or--
	sudo make ARCH=amd64 FLAVOUR=amd64 container

To create the container, the iso-hybrid image must have been created previously. Running the previous command also launches the creation of the iso-hybrid, if it has not been generated yet.
