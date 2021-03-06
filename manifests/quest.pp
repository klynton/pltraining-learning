class learning::quest ($git_branch='release') {
  
  $doc_root = '/var/www/html/questguide/'
  $proxy_port = '80'
  $graph_port = '90'

  include nginx

  nginx::resource::vhost { "_":
    listen_port    => "${proxy_port}",
    listen_options => 'default',
    www_root       => $doc_root,
    require        => File['doc_root'],
  }

  # Serve Graphite

  class { 'apache':
    default_vhost => false,
  }

  apache::vhost { "*:${graph_port}":
    manage_docroot => false,
    port           => $graph_port,
    servername     => 'learning.puppetlabs.vm',
    docroot        => '/opt/graphite/webapp',
    wsgi_application_group      => '%{GLOBAL}',
    wsgi_daemon_process         => 'graphite',
    wsgi_daemon_process_options => {
      processes          => '5',
      threads            => '5',
      display-name       => '%{GROUP}',
      inactivity-timeout => '120',
    },
    wsgi_import_script          => '/opt/graphite/conf/graphite.wsgi',
    wsgi_import_script_options  => {
      process-group     => 'graphite',
      application-group => '%{GLOBAL}'
    },
    wsgi_process_group          => 'graphite',
    wsgi_script_aliases         => {
      '/' => '/opt/graphite/conf/graphite.wsgi'
    },
    headers => [
      'set Access-Control-Allow-Origin "*"',
      'set Access-Control-Allow-Methods "GET, OPTIONS, POST"',
      'set Access-Control-Allow-Headers "origin, authorization, accept"',
    ],
    directories => [{
      path => '/media/',
      order => 'deny,allow',
      allow => 'from all'}
    ]
  }

  # Create docroot for lvmguide files, so the website files
  # can be put in place

  file { '/var/www/html':
    ensure  => directory,
  }

  file { 'doc_root':
    path    => $doc_root,
    ensure  => directory,
    owner   => 'nginx',
    group   => 'nginx',
    mode    => '755',
    require => Package['nginx'],
  }

  package { 'tmux':
    ensure  => 'present',
    require => Class['localrepo'],
  }

  package { 'nodejs':
    ensure  => present,
    require => Class['localrepo'],
  }

  package { 'graphviz':
    ensure  => present,
    require => Class['localrepo'],
  }

  # Pre-install graphite packages
  include learning::graphite_reqs

  package { 'python-pip':
    ensure => present,
    require => Class['localrepo'],
  }

  file { '/usr/bin/pip-python':
    ensure  => symlink,
    target  => '/usr/bin/pip',
    require => Package['python-pip'],
    before  => Class['learning::graphite_reqs'],
  }

  file { ['/opt/quest', '/opt/quest/bin', '/opt/quest/gems']:
    ensure => directory,
  }

  exec { 'install jekyll':
    command => '/opt/puppetlabs/puppet/bin/gem install jekyll -i /opt/quest/gems -n /opt/quest/bin --source https://rubygems.org/',
    creates => '/opt/puppetlabs/puppet/bin/jekyll',
    require => [File['/opt/quest/bin'], File['/opt/quest/gems'], Package['nodejs']],
  }

  vcsrepo { '/usr/src/courseware-lvm':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/puppetlabs/courseware-lvm.git',
  }

  exec { 'rake update':
    environment => ["GH_BRANCH=${git_branch}"],
    command     => "/opt/puppetlabs/puppet/bin/rake update",
    cwd         => '/usr/src/courseware-lvm/',
    require     => [Exec['install-pe'], Exec['install jekyll'], Vcsrepo['/usr/src/courseware-lvm'], Exec['install rspec']],
  }

  service { 'puppet':
    ensure  => stopped,
    enable  => false,
    require => Exec['install-pe'],
  }

}
