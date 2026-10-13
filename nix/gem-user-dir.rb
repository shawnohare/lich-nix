# This preload also runs in raw Ruby children through RUBYOPT. Respect their
# GEM_HOME/GEM_PATH (e.g. repair staging); only redirect explicit user installs.
require "rubygems"

target = ENV.fetch("LICHNIX_GEM_HOME")
raise "LICHNIX_GEM_HOME must be an absolute path" unless target.start_with?("/")

Gem.define_singleton_method(:user_dir) { target }
Gem.clear_paths
