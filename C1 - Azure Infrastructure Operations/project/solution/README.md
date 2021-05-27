# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction and overview
This project deploys a customizable and scalable web server in Azure. 
Packer is used for Server Templating. The contained a Packer template ([server.json](server.json)) extends a UbuntuServer 18.04-LTS image with a lightweight webserver. 
Terraform is used for infrastructure creation. The contained Terraform templates ([main.tf](main.tf) and [vars.tf](vars.tf)) deploy all necessary resources in a configurable way.

### Getting Started
1. Fullfill the [Dependencies](#dependencies): Create an Azure Account if you don't have one and install the necessary tools.
2. Follow the [Instructions](#instructions) for a quick start (happy path).
3. Customize the templates if necessary with the details found in [Customizations](#customizations).

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
In order to use this project the following steps are mandatory:
1. Server Templating / Packer
* Ensure that the Packer template [server.json](server.json) contains the appropriate 'subscription_id' along with 'client_id' and 'client_secret'. If the Azure command line interface is available the 'subscription_id' is sufficient.
* Run packer by executing 'packer build server.json'. (An example output of 'packer build server.json' can be found in [packer-build-server-output.txt](packer-build-server-output.txt).)
* After completion the resource group 'udacity-rg' contains the created image 'myPackerImage'.

2. Infrastructure Creation / Terraform
* Ensure that you are logged in on the Azure command line interface ('az login') and that the desired subscription is selected ('az account set -s <Subscription_ID>')
').
* Initialize Terraform by executing 'terraform init' in the directory that contains the Terraform templates ([main.tf](main.tf) and [vars.tf](vars.tf)).
* Review the resources that will be created by calling 'terraform plan -out plan.out'. (An example plan is found in [solution.plan](solution.plan).)
* Deploy your infrastructure by applying the plan via 'terraform apply plan.out'. (An example output of 'terraform apply solution.plan' can be found in [terraform-apply-solution-output.txt](terraform-apply-solution-output.txt).)

### Customizations
1. Server Templating / Packer
* Besides the variables for 'subscription_id', 'client_id', and 'client_secret mentioned in the instructions, Packer has no other variables in [serrver.json](server.json).
* However, it might be necessary to adjust the 'location' where the image will be created or the used base image (e.g. replacing "18.04-LTS" with "20.04-LTS").

2. Infrastructure Creation / Terraform
* Terraform variables are defined in [vars.tf](vars.tf).
* These include the 'prefix' for all ressource, the 'location' where all ressources are created, the 'username' and 'password' for the virtual machines, and the 'vmcount' that defines the number of VMs to be used.
* In order to change properties defined via variables just edit [vars.tf](vars.tf) (e.g. to use another location or more VMs).


### Output
After successfull execution of Packer and Terraform as explained in the [Instructions](#instructions) you deployed a IaaS web server in Azure.

It is based on a server template that bundles UbuntuServer and the lightweight webserver application into a custom image.

The necessary infrastucture is created and managed as infrastructure as code which eases instantiation and scaling.