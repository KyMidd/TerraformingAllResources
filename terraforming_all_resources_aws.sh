# Generate .tf and .tfstate for existing AWS VPC resources
#  Author: Kyler Middleton, 7.6.2019

# Limitations/bugs
# SG rules are stripped of descriptions during import for some reason


#/bin/bash

# Establish directory for temp config files
mkdir temp

# Export single region
export AWS_REGION=us-east-2

# Find all files in AWS, generate terraform config for them in individual files in temp folder
terraforming help | grep terraforming | grep -v help | awk '{print "terraforming", $2, ">", "temp/"$2".tf";}' | bash

# Build the .tfstate file as empty so it can be iterated on
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
wc -l temp/*.tf | grep ' [0,2-9].' | awk '{print $2}' | sed s/.tf// $1 | sed s:temp/:: | awk '{print "terraforming", $1, "--tfstate", "--merge=terraform.tfstate", "--overwrite";}' | bash

# Delete previous terraform_config.tf if it exists
rm terraform_config.tf

# Build single file with all .tf configuration in it
wc -l temp/*.tf | grep ' [0,2-9].' | awk '{print $2}' | sed s/.tf// $1 | sed s:temp/:: | awk '{print "terraforming", $1, ">>", "terraform_config.tf";}' | bash

# Fixup file for terraform 0.12
terraform 0.12upgrade
# Respond with yes when prompted

# Remove temp directory, no longer needed
rm -rd temp
