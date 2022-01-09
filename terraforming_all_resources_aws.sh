# Generate .tf and .tfstate for existing AWS VPC resources
#  Author: Kyler Middleton, 7.8.2019

# Limitations/bugs
# SG rules are stripped of descriptions during import for some reason


#/bin/bash -e

# Establish directory for temp config files
echo "Creating temp directory to stash files"
mkdir temp

# Export single region
echo "Which region do you want to run against, e.g. us-east-2"
read region
export AWS_REGION=$region

# Find all files in AWS, generate terraform config for them in individual files in temp folder
echo "Utilizing terraforming to sync config files for all resources into temp folder"
terraforming help | grep terraforming | grep -v help | awk '{print "terraforming", $2, ">", "temp/"$2".tf";}' | bash

# Build the .tfstate file as empty so it can be iterated on
echo "Over-writing terraform.tfstate file with an empty shell"
cat <<EOL > terraform.tfstate
{
  "version": 1,
  "serial": 12,
  "modules": [
    {
      "path": [
        "root"
      ],
      "outputs": {
      },
      "resources": {
      }
    }
  ]
}
EOL

# Identify which resource .tf files aren’t empty (resources exist of that type) and generate tfstate for each existing resource
echo "Identify resource types which exist, generate tfstate for them"
find temp -type f -not -empty -name '*.tf' -exec basename {} \; | sed -e 's/.tf//' $1 | awk '{print "terraforming", $1, "--tfstate", "--merge=terraform.tfstate", "--overwrite";}' | bash

# Delete previous terraform_config.tf if it exists
echo "Removing terraform_config.tf old files"
rm -f terraform_config.tf

# Build single file with all .tf configuration in it
echo "Building a single terraform_config.tf file with configuration for all existing resources"
find temp -type f -not -empty -name '*.tf' -exec basename {} \; | sed -e 's/.tf//' $1 | awk '{print "terraforming", $1, ">>", "terraform_config.tf";}' | bash

# remove previous version.tf file if exists
echo "Removing versions.tf file which block 0.12upgrade process"
rm -f versions.tf

# Init terraform
echo "init and format Terraform"
if $(terraform init && terraform fmt); then
    echo "Code is initialized"
else
    echo "*******************************"
    echo "There were formatting issues with your code which isn't unusual"
    echo "Review the issues and manually fix them in the config file"
    echo "Test against with command \"terraform init && terraform fmt\""
    echo "*******************************"
fi

# Remove temp directory, no longer needed
echo "Deleting temp directory and all contents"
rm -rd temp
