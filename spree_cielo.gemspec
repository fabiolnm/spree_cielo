$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "spree_cielo/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "spree_cielo"
  s.version     = SpreeCielo::VERSION
  s.authors     = ["Fábio Luiz Nery de Miranda"]
  s.email       = ["fabio@miranti.net.br"]
  s.homepage    = "https://github.com/fabiolnm/spree_cielo"
  s.summary     = "A gem providing Cielo Gateways for Spree Commerce"
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "spree_core"
end
