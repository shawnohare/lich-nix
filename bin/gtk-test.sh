bundle exec ruby -e '
  require "gtk3"

  Gtk.init

  window = Gtk::Window.new
  window.title = "GTK / Nix Test"
  window.set_default_size(400, 200)
  window.signal_connect("destroy") { Gtk.main_quit }

  window.add(Gtk::Label.new("GTK works on macOS"))
  window.show_all

  Gtk.main
'
