Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_import_products'
  s.version     = '3.1.0'
  s.summary     = "spree_import_products ... imports products. From a CSV file via Spree's Admin interface"
  #s.description = 'Add (optional) gem description here'
  s.required_ruby_version = '>= 2.2.2'

  s.author            = '2BeDigital'
  s.email             = '2bedigital@2bedigital.com'
  s.homepage          = 'http://www.2BeDigital.com'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'


  s.add_dependency('spree_core', '>= 3.1.0')
  s.add_dependency('spree_auth_devise')
  s.add_dependency('delayed_job_active_record')
  s.add_dependency('daemons')
  s.add_dependency('coffee-script')

  #s.add_development_dependency('spree_sample')
  s.add_development_dependency('sqlite3')
  s.add_development_dependency('ffaker', '~> 2.2.0')
  s.add_development_dependency('rspec-rails')
  s.add_development_dependency('capybara')
  s.add_development_dependency('launchy', '2.0.5')
  s.add_development_dependency('factory_girl')

  # # Commenting out because bundle install fails with this
  # if RUBY_VERSION < "1.9"
  #   s.add_development_dependency('ruby-debug')
  # else
  #   s.add_development_dependency('ruby-debug19')
  # end

end
