use inc::Module::Install;    #libmodule-install-perl

name 'Mbot';

abstract 'Icinga2 plugin for Mbot';
author 'Marko Punnar <marko@aretaja.org>';
version '1.0';
license 'gpl';
all_from 'lib/Mbot/Plugins/Icinga2.pm';

requires 'Mbot';                        # no package
requires
  'Monitoring::Icinga2::Client::REST';  # libmonitoring-icinga2-client-rest-perl

auto_install;
WriteAll;
