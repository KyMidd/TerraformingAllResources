This script utilizes the terraforming tool to iterate through all resource types
it can handle and build both the .tf config files and the .tfstate state files.

It's written in bash with some interesting sed commands.

Make sure you export your AWS keys or use a profile indicator so this script can
utilize your authentication.
