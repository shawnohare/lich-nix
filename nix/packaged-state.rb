# frozen_string_literal: true

require 'fileutils'

module LichnixPackagedState
  module_function

  def default_home
    root = ENV['LICHNIX_DATA_HOME'] || File.join(
      ENV['XDG_DATA_HOME'] || File.join(ENV.fetch('HOME'), '.local', 'share'), 'lichnix'
    )
    File.expand_path(File.join(root, 'runtime'))
  end

  # Only seed absent files. Never traverse a user's symlink while copying assets.
  def seed(source, destination)
    return if File.symlink?(destination)
    if File.directory?(source)
      return if File.exist?(destination) && !File.directory?(destination)
      FileUtils.mkdir_p(destination)
      Dir.children(source).each { |name| seed(File.join(source, name), File.join(destination, name)) }
    elsif !File.exist?(destination)
      begin
        File.open(destination, File::WRONLY | File::CREAT | File::EXCL, 0o644) do |output|
          File.open(source, 'rb') { |input| IO.copy_stream(input, output) }
        end
      rescue Errno::EEXIST
        # Another setup or a user supplied the file; retain their copy.
      end
    end
  end

  def prepare(package, home)
    FileUtils.mkdir_p(home)
    File.open(File.join(home, '.lichnix-setup.lock'), 'a', 0o600) do |lock|
      lock.flock(File::LOCK_EX)
      links = { 'lich.rbw' => '.lichnix-package/lich.rbw', 'lib' => '.lichnix-package/lib' }
      links.each do |name, target|
        path = File.join(home, name)
        next unless File.exist?(path) || File.symlink?(path)
        unless File.symlink?(path) && File.readlink(path) == target
          raise "lichnix: refusing to replace unmanaged #{path}; choose a separate runtime home"
        end
      end
      package_link = File.join(home, '.lichnix-package')
      if File.exist?(package_link) && !File.symlink?(package_link)
        raise "lichnix: refusing to replace #{package_link}"
      end
      %w[data scripts/custom temp maps logs backup sessions].each do |directory|
        FileUtils.mkdir_p(File.join(home, directory))
      end
      %w[scripts data maps logo.png fly64.ico].each do |asset|
        source = File.join(package, asset)
        seed(source, File.join(home, asset)) if File.exist?(source)
      end
      links.each do |name, target|
        path = File.join(home, name)
        File.symlink(target, path) unless File.symlink?(path)
      end
      # Select new core code atomically; mutable scripts/data remain untouched.
      candidate = "#{package_link}.#{Process.pid}"
      begin
        File.symlink(package, candidate)
        File.rename(candidate, package_link)
      ensure
        File.unlink(candidate) if File.symlink?(candidate)
      end
    end
    home
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    LichnixPackagedState.prepare(File.realpath(ARGV.fetch(0)), LichnixPackagedState.default_home)
  rescue StandardError => e
    warn e.message
    exit 1
  end
end
