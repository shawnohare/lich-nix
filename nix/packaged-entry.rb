#!/usr/bin/env ruby
# frozen_string_literal: true

# This Ruby entry point also runs when GUI/elogin/reconnect bypass ruby-lich.
package = File.dirname(File.realpath(__FILE__))
require File.join(package, 'packaged-state')

paths = {
  'home' => ['home'], 'data-dir' => %w[data data-dir],
  'script-dir' => %w[scripts script-dir], 'temp-dir' => %w[temp temp-dir],
  'map-dir' => %w[maps map-dir], 'log-dir' => %w[logs log-dir],
  'backup-dir' => %w[backup backup-dir], 'active-session-dir' => ['active-session-dir'],
  'lib-dir' => %w[lib lib-dir]
}
selected = {}
paths.each do |option, aliases|
  argument = ARGV.reverse.find { |arg| aliases.any? { |name| arg.match?(/^--#{name}=.+$/i) } }
  selected[option] = argument.split('=', 2).last if argument
end
home = File.expand_path(selected['home'] || ENV['LICHNIX_RUNTIME_HOME'] || LichnixPackagedState.default_home)
defaults = {
  'home' => home, 'lib-dir' => File.join(package, 'lib'),
  'data-dir' => File.join(home, 'data'), 'script-dir' => File.join(home, 'scripts'),
  'temp-dir' => File.join(home, 'temp'), 'map-dir' => File.join(home, 'maps'),
  'log-dir' => File.join(home, 'logs'), 'backup-dir' => File.join(home, 'backup'),
  'active-session-dir' => File.join(home, 'sessions')
}
if selected['lib-dir'] && File.expand_path(selected['lib-dir']) != defaults['lib-dir']
  abort 'lichnix: packaged mode uses immutable core libraries; use writeable mode for another source'
end
LichnixPackagedState.prepare(package, home)
ARGV.reject! do |argument|
  paths.values.flatten.any? { |name| argument.match?(/^--#{name}=.+$/i) }
end
paths.each_key do |option|
  key = "LICHNIX_PATH_#{option.upcase.tr('-', '_')}"
  # Explicit home changes reset inherited data defaults; explicit flags still win.
  inherited = ENV[key] unless selected['home'] || option == 'home' || option == 'lib-dir'
  value = File.expand_path(selected[option] || inherited || defaults.fetch(option))
  ENV[key] = value
  ARGV << "--#{option}=#{value}"
  FileUtils.mkdir_p(value) unless option == 'lib-dir'
end
ENV['LICHNIX_RUNTIME_HOME'] = home
$LOAD_PATH.unshift(package) # Legacy require 'lib/...' without writable core copies.
$PROGRAM_NAME = File.join(home, 'lich.rbw')
require 'bundler/setup' # Raw Ruby children must activate the same packaged bundle.
unless ARGV.any? { |arg| %w[-v --version -h --help].include?(arg) || arg.start_with?('--help=') }
  warn 'lichnix: packaged core and gems are immutable. Lich self-update/rollback, gem repair and runtime gem additions are unsupported; upgrade or rebuild through Nix. Scripts and data remain writable.'
end
load File.join(package, 'upstream.rbw')
