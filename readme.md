# Automatic Docker Cluster (UNDER CONSTRUCTION)
This Article describes how i created a Ubuntu Installer with Kickstart File to automatic deploy a Docker Cluster managed with Rancher.

## Concept
The Idea behind was to simply create and scale a docker cluster without configure each node manualy.
I end up with a Ubuntu Kickstart in combination with Static DHCP and DNS entries.
The Kickstart file describes how to partition the disk, installs recomended software, creates users and creates a bootscript. The script gets information about the cluster from a DNS TXT record. like this:

```
DOCKERSCRIPTVERSION=1.10.sh
AGENT=v1.0.2
RANCHERURL={FQDN of the Rancher Master}
ENCRYPTED={YES | NO --> (to enable it, SSL termination Proxy in front of Rancher Master is required.)}
RANCHERPORT={Rancher Master Port}
JOINTOKEN={Token to join nodes to a Enviroment}
```
## HOW TO
### Prepare
Define a IP-Ranche for the Cluster.
Create a DNS Concept.
In my case i use a subdomain (docker.example.local), every host gets a host record with its company wide uniq machine name and a cname entry like node{sequence number}.
#### DHCP Entry
Get the Mac Address of any Host you use in the Cluster and create a Static entry on the DHCP Server.
#### DNS Records
Create a Host entry for every Host you use in the Cluster on the DNS for address resolution.
Create a TXT entry with the following informations:

```
DOCKERSCRIPTVERSION=1.10.sh "Docker Version you want to use"
RANCHERURL={FQDN of the Rancher Master}
ENCRYPTED=NO {YES currently not supported}
RANCHERPORT={Rancher Master Port}
```
#### Personal Install Media

Use my script "bootcdassistant.sh" to copy all files from the iso file.

1. bootcdassistant.sh dump {PATH TO ISO}
2. The Script shows you the path to the dumped files.
3. Navigate to the dumped file directory
4. Use system-config-kickstart to create a Standard Kickstart file, based on your needs and save it twice to your dumped file directory. Named master.cfg and client.cfg
5. Copy the `%post` section from my template template_master.cfg file and paste it into master.cfg
6. Copy the `%post` section from my template template_client.cfg file and paste it into client.cfg
7. Change the variable `sourceurl` on both files to the FQDN of your TXT record.
8. I also recommend to add the following packages to the `%packages` section
	 - ca-certificates
	 - openssl
	 - openssh-server
	 - curl
	 - open-vm-tools --no-install-recommends --> for use in vmware enviroment (esxi, vmware-player, etc..)
9. Open ./isolinux/txt.cfg in your editor
10. Add two new entries for your configuration. something like this:

	``` 
	label ranchermaster
  	menu label ^Rancher Master
  	kernel /install/vmlinuz
  	append  file=/cdrom/preseed/ubuntu-server.seed vga=788 initrd=/install/	initrd.gz ks=cdrom:/master.cfg -- 
  	
  	label rancherclient
  	menu label ^Rancher Client
  	kernel /install/vmlinuz
  	append  file=/cdrom/preseed/ubuntu-server.seed vga=788 initrd=/install/	initrd.gz ks=cdrom:/client.cfg -- 
  	
	```
 	Modify the label, menu label and path to your kickstart file. I've had 	troubles storing the cfg files in a directory on the cdrom, but root worked 	fine.

12. To create the ISO, run: `bootcdassistant.sh create {path to dumped file directory} {name of cdvolume} {path to new iso file}`
	
### Installation
#### MASTER
Make shure you have created a static entry on your DHCP Server and a host entry on your DNS. Verify your previous created TXT reccord. (Required values: DOCKERSCRIPTVERSION, RANCHERPORT)

1. Boot your Server, VM, whatever with your new created bootCD
2. Choose your previous created entry `Rancher Master`
3. Ubuntu will be installed automatically

	- gets its Hostname from DNS
 	- gets Static IP from DHCP
 	- installs predefined packages
 	- installs udpates
 	- fetch Dockerversion, Rancherport --> installs Docker and Rancher Server
 	- takes 10-30 Minutes

4. Open a Browser and browse to {FQDN of Master}:{Rancherport}
5. Create a Enviroment and choose your perfered Orchestration Tecnology
6. Navigate to add a host. You will see something like:
 
 	```
 	sudo docker run -d --privileged \
 	-v /var/run/docker.sock:/var/run/docker.sock \
 	-v /var/lib/rancher:/var/lib/rancher \
 	rancher/agent:{RANCHERVERSION} \
 	http://{RANCHERURL}:{RANCHERPORT}/v1/scripts/{JOINTOKEN}
 	```
7. IN the DNS TXT Record add or modify the following entries based on the RUN Command in the "add Host page" of Rancher UI (step 6 ): 

	```
	AGENT={RANCHERVERSION}
	RANCHERURL={RANCHERURL}
	JOINTOKEN={JOINTOKEN}
	```
	
#### CLIENT
Make shure you've modified the TXT entriy as described before, a static DHCP entry exists and a Host entry on your DNS is present.

1. Boot your Server, VM, whatever with your new created bootCD
2. Choose your previous created entry `Docker Client`
3. Ubuntu will be installed automatically

	- gets its Hostname from DNS
 	- gets Static IP from DHCP
 	- installs predefined packages
 	- installs udpates
 	- fetch Dockerversion, Rancherport, Rancherhost, Jointoken --> installs Docker and Starts a Rancher Client Container based on the informations in yout TXT Record.
 	- takes 10-30 Minutes
4. The Host schould automatically apear in the Rancher UI within 2-10 Minutes.
 
## Recources
 
 - https://pricklytech.wordpress.com/2013/04/21/ubuntu-server-unattended-installation-custom-cd/




	






