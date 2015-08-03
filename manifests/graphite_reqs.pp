# Pre-install the graphite packages to speed up installation and
# enable offline use.

class learning::graphite_reqs {
  Package {
    provider => 'pip',
    require  => Package['python-pip'],
  }
  package { 'python-devel':
    provider => 'yum',
    before   => Package['twisted','django-tagging','txamqp'],
  }
  package { 'django-tagging':
    ensure => '0.3.1',
  }
  package { 'twisted':
    ensure => '11.1.0',
  }
  package { 'txamqp':
    ensure => '0.4',
  }
  package { 'graphite-web':
    ensure => '0.9.12',
  }
  package { 'carbon':
    ensure => '0.9.12',
  }
  package { 'whisper':
    ensure => '0.9.12',
  }
  package { 'python-sqlite3dbm':
    ensure => '0.1.4-6.el7',
  }
  # Workaround for package installation target that isn't recognized by
  # pip.
  # https://github.com/graphite-project/carbon/issues/86
  file { '/usr/lib/python2.6/site-packages/graphite_web-0.9.12-py2.6.egg-info':
    target  => '/opt/graphite/webapp/graphite_web-0.9.12-py2.6.egg-info',
    require => Package['graphite-web'],
    ensure  => link,
  }
  file { '/usr/lib/python2.6/site-packages/carbon-0.9.12-py2.6.egg-info':
    target  => '/opt/graphite/lib/carbon-0.9.12-py2.6.egg-info',
    require => Package['carbon'],
    ensure  => link,
  }
}
