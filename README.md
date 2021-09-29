Dwarf-NG
========

In a nutshell, dwarf is OpenStack API on top of local libvirt/KVM. It supports
a subset of the Keystone, Glance and Nova APIs to manage images and instances
on the local machine.

Dwarf-NG is a fork of the original juergh/dwarf project with outstanding PRs
and additional enhancements merged.  Dwarf-NG is still a little behind the times
as it is still Python 2 but I'm using it so I want to keep my current version
in a central place.


Restrictions
------------

Lots :-) It only supports a subset of the OpenStack API and it currently
doesn't do user authentication. Meaning everybody who can log into the machine
can manipulate all images and instances managed through dwarf.

Everything is serialized and blocking. All calls to dwarf will be served in the
order they're received and only return after they've finished. There's no
scheduling and background processing.


Configuration
-------------

After installation, check that the settings in '/etc/dwarf.conf' match your
environment. You need to restart dwarf if you make any modifications:
$ sudo initctl restart dwarf

Set the OpenStack environment variables (modify the port number accordingly, if
you changed it in the config file):
$ export OS_AUTH_URL=http://localhost:35357/v2.0/
$ export OS_COMPUTE_API_VERSION=1.1
$ export OS_REGION_NAME=dwarf-region
$ export OS_TENANT_NAME=dwarf-tenant
$ export OS_USERNAME=dwarf-user
$ export OS_PASSWORD=dwarf-password


Supported OpenStackClient CLI commands
--------------------------------------

At the moment, the following commands are supported:

token issue
catalog list

flavor create
flavor delete
flavor list
flavor show

image create
image delete
image list
image set
image show

keypair create
keypair delete
keypair list
keypair show

server create
server delete
server list
server reboot
server rebuild
server show


Notes
-----

Default compute flavors are automatically added, check them with:
$ openstack flavor list

Before you can boot an instance, you need to add an image and a keypair:
$ openstack keypair create <key-name>
$ openstack image create --file <image-filename> <image-name>

When booting a server, the server will receive a DHCP IP address from
libvirt's dnsmasq. It takes a bit until that happens, check the status with:
$ openstack server show <server-name-or-id>


Debugging
---------

Check the log at /var/lib/dwarf/dwarf.log.
