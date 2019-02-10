 # FoundationDemoAddon
PowerShell based kit that deploys the entire Nutanix stack ontop of the normal installer.

Purpose:
This application installs ontop of a baremetal cluster after normal AOS foundation is done.
It runs on hosted POC systems but also Baremetal.
This code is just commited for insight there is no installer for this service yet.

* Creates Storage containers
* Creates Network
* Uploads required images
* Installs Prism Central using REST (Latest auto version)
* Sets up 2 domain controllers, creates a domain using sysprep
* Sets DNS servers in the entire stack to the created domain controllers
* Sets NTP for the entire stack
* Sets ISCSI IP for Prism Element
* Maps AD Domain Admins to the Prism X Admin role.
* Creates a Domain Admin account for the requesting user
* Creates dummy AD content, accounts, users and groups for multitenant setup.
* Registers Prism Element
* Installs Files in Prism Element (Latest auto version)
* Creates 3 shares (home, shared, public)
* Joins Prism Element to Prism Central
* Joings Prism Element and Prism Central to the AD Domain
* Resets SSH passwords
* Sets up SSP projects in multitenant demo.
* Installs CALM
* Runs software updates, updating CALM to the latest version.
* Installs Flow
* Installs XPlay Demo
* Installs Workshop demo

Description:
This kit is intented to run as a service, hence installer is not available yet.

Future releases will have a foundation like VM that can be used for offline installs

Service is currently running in the Nutanix internal network.

Use foundation emails, slack or its built in website (not included) to create a job.

This creates a job

Job Queueing is handled by the backend processor.

Job execution is handled by the Base-Outgoing queue processor. 

Both should be a scheduled task. 

1 or 2 modules require IE for COM interaction. This is for RPA based automation. There are some minor items that cannot be automated using REST or other tools. Hence this RPA requirement. This will be removed as soon as possible. 

Hence the Base-Outgoing-Queue-Processor.ps1 should run in console.

See modules dir for all functions and modules created.

There are more then 30 available. 

Todo:
There is no installer yet.

This commit is just to store the code. 

Using the full kit requires the installer.

SMTP setup is not included in this version.

Requirements:
*This runs on Posh 5.1
*This requires POSH-SSH to be installed
*This requires the nutanix CMDlets to be installed.
*Powershell remoting needs to be enabled on the local host

