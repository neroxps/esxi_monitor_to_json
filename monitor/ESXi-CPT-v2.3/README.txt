The ESXi Community Packaging Tools (ESXi-CPT) is a set of user-friendly scripts that
can be used to create deployment packages of drivers and add-ons for VMware ESXi 5.x and 6.x.

Included scripts
- tgz2vib5.cmd converts a tgz file to a VIB file.
- vib2zip.cmd converts one or multiple VIB files into an Offline Bundle zip file.

Requirements
- The scripts runs on Windows XP or newer (both 32-bit and 64-bit).
- The driver or add-on package that you want to deploy needs to be available
  either in a tgz (tar.gz) package format or as an on-disk directory structure.

Instructions for tgz2vib5.cmd
- Please see the online documentation at http://esxi-cpt.v-front.de
  for up-to-date instructions

Instructions for vib2zip.cmd
- Please see the online documentation at http://esxi-cpt.v-front.de
  for up-to-date instructions

Licensing
- All included scripts are licensed under the GNU GPL version 3 (see the included
  file COPYING.txt).
- They are distributed with and make use of several tools that are freely
  available, but are partly under different licenses (see the included file
  tools\README.txt for details.)

Support
- If you have trouble using the scripts then please send an email to
  ESXi-CPT@v-front.de. Be sure to include the log file of the script.
  Otherwise I might just ignore your message.
