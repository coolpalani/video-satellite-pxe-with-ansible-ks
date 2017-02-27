#!/usr/bin/perl

#### re-done in Perl, based on the API calls in the .sh version of this same script

#  The following assumes: a manual inventory set up with ADMIN permissions
#  assigned to the limited user (noted as user:password below).  My
#  "Provisioning" inventory is inventory #11.
#
#  This will delete the newly provisioned system from inventory when complete.
#  You can remove the DELETE call if you like.  Or it could be modified to
#  remove this from the "Provisioning" group.  As it runs below, the host is
#  removed completely after the callback, but it gets re-discovered when the 
#  scheduled template runs.
#
#  VARS TO SET:

# user credentials for the limited account
$username = 'helpyhelper1';
$password = 'helpyhelper1';

# inventory ID
$invid = 11;

# callback template ID
$cbkid = 198;

# Ansible Tower URL
$towerurl = 'https://ansibletower.lab';


# This turns the FQDN into a var (you might want to use an IP if your DNS isn't configured yet at this point in the build)
chomp ($newsrvname = `hostname -f`);

## This defines the curl command with which we INSERT
$insert =<<ALLDONE;
curl -s -f -k -H 'Content-Type: application/json' -XPOST -d '{
	"name": "$newsrvname",
	"description": "Manually Inserted Server",
	"inventory": "$invid",
	"enabled": true
}' --user helpyhelper1:helpyhelper1 $towerurl/api/v1/hosts/

ALLDONE


## Parse the reply and extract the first piece of it... next, remove everything that's not a digit.
($newsrvid,undef) = split (/\,/,`$insert`);
$newsrvid =~ s/[^0-9]//g;



## This defines the command which runs the provisioning callback
$callback =<<ALLDONE;
curl --insecure --data "host_config_key=KEV" $towerurl/api/v1/job_templates/$cbkid/callback/
ALLDONE

## We execute the request for the provisioning callback
system($callback);


## This defines the API call to delete the new system from the inventory
$delete =<<ALLDONE;
curl -k -H 'Content-Type: application/json' -XDELETE --user $username:$password $towerurl/api/v1/hosts/$newsrvid/
ALLDONE


## Race condition!!  We can't delete from inventory until the playbook starts
sleep(30);


## We execute the delete command and finish out
system($delete);


