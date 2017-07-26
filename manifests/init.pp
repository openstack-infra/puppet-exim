# The 'routers' and 'transports' parameters are lists of hashes of
# hashes.  Each entry of the outer hash corresponds to a single router
# or transport definition, with the key being the name of the router
# or transport.  The inner hash is a set of options for that router or
# transport which are set verbatim, except that 'flag' options (where
# Exim expects merely the presence or absence of the option with no
# value associated) are passed in as booleans, where a value of true
# means the option should be present.  E.g.:
#
# routers => [
#   {'storyboard' => {
#      'driver'                     => 'redirect',
#      'local_parts'                => 'storyboard',
#      'local_part_suffix_optional' => true,
#      'local_part_suffix'          => '-bounces : -bounces+*',
#      'data'                       => ':blackhole:',
#   }}
# ]
#
# For the current Exim configuration, see:
# http://www.exim.org/exim-html-current/doc/html/spec_html/index.html

class exim(
  $local_domains            = '@',
  $mailman_domains          = [],
  $queue_interval           = '30m',
  $queue_run_max            = '5',
  $queue_smtp_domains       = undef,
  $routers                  = [],
  $smarthost                = false,
  $sysadmins                = [],
  $transports               = [],
  $smtp_accept_max          = '',
  $smtp_accept_max_per_host = '',
) {

  include ::exim::params

  package { $::exim::params::package:
    ensure => present,
  }

  if ($::osfamily == 'RedHat') {
    service { 'postfix':
      ensure      => stopped
    }
    file { $::exim::params::sysdefault_file:
      ensure  => present,
      content => template("${module_name}/exim.sysconfig.erb"),
      group   => 'root',
      mode    => '0444',
      owner   => 'root',
      replace => true,
      require => Package[$::exim::params::package],
    }
  }

  if ($::osfamily == 'Debian') {
    file { $::exim::params::sysdefault_file:
      ensure  => present,
      content => template("${module_name}/exim4.default.erb"),
      group   => 'root',
      mode    => '0444',
      owner   => 'root',
      replace => true,
      require => Package[$::exim::params::package],
    }
  }

  service { $::exim::params::service_name:
    ensure     => running,
    hasrestart => true,
    subscribe  => [
      File[$::exim::params::config_file],
      File[$::exim::params::sysdefault_file],
    ],
    require    => Package[$::exim::params::package],
  }

  file { $::exim::params::config_file:
    ensure  => present,
    content => template("${module_name}/exim4.conf.erb"),
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    replace => true,
    require => Package[$::exim::params::package],
  }

  file { '/etc/aliases':
    ensure  => present,
    content => template("${module_name}/aliases.erb"),
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    replace => true,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
