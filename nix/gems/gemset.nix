{
  ascii_charts = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1gnbfh6xfww0rnrms3ryxi5y2b0s8xirxzb5cs2b20cgaci1ci1h";
      type = "gem";
    };
    version = "0.9.1";
  };
  ast = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10yknjyn0728gjn6b5syynvrvrwm66bhssbxq8mkhshxghaiailm";
      type = "gem";
    };
    version = "2.4.3";
  };
  atk = {
    dependencies = ["glib2" "rake"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yklm8rdvxl63mqyk8z74idvsqaj9i2i2flsm73px88bqx937jmh";
      type = "gem";
    };
    version = "4.3.6";
  };
  base64 = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yx9yn47a8lkfcjmigk79fykxvr80r4m1i35q82sxzynpbm7lcr7";
      type = "gem";
    };
    version = "0.3.0";
  };
  benchmark = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0v1337j39w1z7x9zs4q7ag0nfv4vs4xlsjx2la0wpv8s6hig2pa6";
      type = "gem";
    };
    version = "0.5.0";
  };
  bigdecimal = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1g9zi8c4i7g8zz0c3hxrw6mblrjvgn7akys60clb9si7c1k1gljk";
      type = "gem";
    };
    version = "4.1.2";
  };
  cairo = {
    dependencies = ["native-package-installer" "pkg-config" "red-colors"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08x6f2idyfnylq0b66mqi8lf5mjvff2y2q02n5hq0x4i3ha5cwz5";
      type = "gem";
    };
    version = "1.18.5";
  };
  cairo-gobject = {
    dependencies = ["cairo" "glib2"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hxblh0k3h2ar4y47lify1fwjskmisvac24v72xwgn3q7znvds36";
      type = "gem";
    };
    version = "4.3.6";
  };
  concurrent-ruby = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1c2i64xsd35vijnb50rxb70g508s0x674xi0qpyyb8jy7bncl4j4";
      type = "gem";
    };
    version = "1.3.7";
  };
  connection_pool = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "02ifws3c4x7b54fv17sm4cca18d2pfw1saxpdji2lbd1f6xgbzrk";
      type = "gem";
    };
    version = "3.0.2";
  };
  curses = {
    groups = ["profanity"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1qkq83izdj0lzqwwf8c53b6dzcfcx47mzh5902yg9l1sabyjgkr6";
      type = "gem";
    };
    version = "1.6.0";
  };
  date = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h0db8r2v5llxdbzkzyllkfniqw9gm092qn7cbaib73v9lw0c3bm";
      type = "gem";
    };
    version = "3.5.1";
  };
  diff-lcs = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qlrj2qyysc9avzlr4zs1py3x684hqm61n4czrsk1pyllz5x5q4s";
      type = "gem";
    };
    version = "1.6.2";
  };
  digest = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0isr75hlidx0k50kflsimhs1y6l64mmchr6587fdbmvjwas14cxb";
      type = "gem";
    };
    version = "3.2.1";
  };
  drb = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wrkl7yiix268s2md1h6wh91311w95ikd8fy8m5gx589npyxc00b";
      type = "gem";
    };
    version = "2.2.3";
  };
  ffi = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kqasqvy8d7r09ri4n6bkdwbk63j7afd9ilsw34nzlgh0qp69ldw";
      type = "gem";
    };
    version = "1.17.4";
  };
  fiddle = {
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vifygrkw22gcd4wzh8gc4pv6h1zpk6kll6mmprrf5174wvfxa3z";
      type = "gem";
    };
    version = "1.1.8";
  };
  fileutils = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00kf7icj8r5w9cwlsaymp9qallw8yy5g0n4jyfrbsh159vsisswc";
      type = "gem";
    };
    version = "1.8.0";
  };
  gdk3 = {
    dependencies = ["cairo-gobject" "gdk_pixbuf2" "pango" "rake"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12wfqjmxkdkn0bs7gqn04ac5ip0awx8jxvmmrykny8p19lrfsrw5";
      type = "gem";
    };
    version = "4.3.6";
  };
  gdk_pixbuf2 = {
    dependencies = ["gio2" "rake"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ihv48n5vq7xrxwspm2icx9rszgygkhkcg6w4lv0cygay695nmn2";
      type = "gem";
    };
    version = "4.3.6";
  };
  gio2 = {
    dependencies = ["fiddle" "gobject-introspection"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "19fmvs919hnr5i9xwq9fw4vgnym3j37ngnbz1zfb8921c6qpvlsi";
      type = "gem";
    };
    version = "4.3.6";
  };
  glib2 = {
    dependencies = ["native-package-installer" "pkg-config"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1k71h37jv0hn61sw9nrmph6mlw1y2d4bibk43163ndj7v1vfq76j";
      type = "gem";
    };
    version = "4.3.6";
  };
  gobject-introspection = {
    dependencies = ["glib2"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0sw7fny16rhvdbbnk80vikl081jkbmmyg2r3b3i47hmyamjzc2bg";
      type = "gem";
    };
    version = "4.3.6";
  };
  gtk3 = {
    dependencies = ["atk" "gdk3"];
    groups = ["gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16cwls02xpdy7ra5cz8jqpfhdk6zwryjhw4ipvmr0chv0la23vdd";
      type = "gem";
    };
    version = "4.3.6";
  };
  json = {
    groups = ["default" "development" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1b1rabz30grash5wh0lcv109w2ggggmmbclwnajqrcdk7wrps2k7";
      type = "gem";
    };
    version = "2.19.4";
  };
  kramdown = {
    dependencies = ["rexml"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yh2gwpwhh0p4vc0aabzn0hb55av0wkcq3gh3w8zkdk69hh4598v";
      type = "gem";
    };
    version = "2.5.2";
  };
  language_server-protocol = {
    groups = ["default" "development" "vscode"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1k0311vah76kg5m6zr7wmkwyk5p2f9d9hyckjpn3xgr83ajkj7px";
      type = "gem";
    };
    version = "3.17.0.5";
  };
  lint_roller = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11yc0d84hsnlvx8cpk4cbj6a4dz9pk0r1k29p0n1fz9acddq831c";
      type = "gem";
    };
    version = "1.1.0";
  };
  logger = {
    groups = ["default" "vscode"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
      type = "gem";
    };
    version = "1.7.0";
  };
  matrix = {
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nscas3a4mmrp1rc07cdjlbbpb2rydkindmbj3v3z5y1viyspmd0";
      type = "gem";
    };
    version = "0.4.3";
  };
  mini_portile2 = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12f2830x7pq3kj0v8nz0zjvaw02sv01bqs1zwdrc04704kwcgmqc";
      type = "gem";
    };
    version = "2.8.9";
  };
  native-package-installer = {
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0bvr9q7qwbmg9jfg85r1i5l7d0yxlgp0l2jg62j921vm49mipd7v";
      type = "gem";
    };
    version = "1.1.9";
  };
  open-uri = {
    dependencies = ["stringio" "time" "uri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1jl7i0w0vhxpvj54707cpcpqi00maf1dma0mxmm99rirmkyhckvv";
      type = "gem";
    };
    version = "0.5.0";
  };
  openssl = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zazkk5q3p2ldd23ka04wypsz2g8gqwwainf3d58j0kvdc9p8yg2";
      type = "gem";
    };
    version = "4.0.1";
  };
  os = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gwd20smyhxbm687vdikfh1gpi96h8qb1x28s2pdcysf6dm6v0ap";
      type = "gem";
    };
    version = "1.1.4";
  };
  ostruct = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04nrir9wdpc4izqwqbysxyly8y7hsfr4fsv69rw91lfi9d5fv8lm";
      type = "gem";
    };
    version = "0.6.3";
  };
  ox = {
    dependencies = ["bigdecimal"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15j85zxs6c8ykis9770ii7m7rbbx5vxkqqk9shqicxamzd4wpafl";
      type = "gem";
    };
    version = "2.14.26";
  };
  pango = {
    dependencies = ["cairo-gobject" "gobject-introspection"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p5ygivdz43ca96fap6k9ric7m72nm908cix2p0gl84blxav7sq4";
      type = "gem";
    };
    version = "4.3.6";
  };
  parallel = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0z9cbfdfr83k8xhrh1nr4f4z8ryfivfr3gv3fpk22hczwg9q4xrk";
      type = "gem";
    };
    version = "2.0.1";
  };
  parser = {
    dependencies = ["ast" "racc"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0m2xqvn1la62hji1mn04y59giikww95p2hs0r4y2rrz3mdxcwyni";
      type = "gem";
    };
    version = "3.3.11.1";
  };
  pkg-config = {
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cy75ssbwjzi9z3zwfx2zq3b8xvpy9rbdf1rnhi3v612acfgiy9k";
      type = "gem";
    };
    version = "1.6.5";
  };
  prism = {
    groups = ["default" "development" "vscode"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11ggfikcs1lv17nhmhqyyp6z8nq5pkfcj6a904047hljkxm0qlvv";
      type = "gem";
    };
    version = "1.9.0";
  };
  racc = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0byn0c9nkahsl93y9ln5bysq4j31q8xkf2ws42swighxd4lnjzsa";
      type = "gem";
    };
    version = "1.8.1";
  };
  rainbow = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0smwg4mii0fm38pyb5fddbmrdpifwv22zv3d3px2xx497am93503";
      type = "gem";
    };
    version = "3.1.1";
  };
  rake = {
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "009p524zl0p0kfa65nii8wdmaigkmawv9pbvlcffky7islmmp0nb";
      type = "gem";
    };
    version = "13.4.2";
  };
  rbs = {
    dependencies = ["logger" "prism" "tsort"];
    groups = ["vscode"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09ggg2zk0qrh0mc3fa23xjbn2gzqxd0jfqj6qm6460ydcqg6fxdg";
      type = "gem";
    };
    version = "4.0.2";
  };
  red-colors = {
    dependencies = ["json" "matrix"];
    groups = ["default" "gtk"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16lj0h6gzmc07xp5rhq5b7c1carajjzmyr27m96c99icg2hfnmi3";
      type = "gem";
    };
    version = "0.4.0";
  };
  redis = {
    dependencies = ["redis-client"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bpsh5dbvybsa8qnv4dg11a6f2zn4sndarf7pk4iaayjgaspbrmm";
      type = "gem";
    };
    version = "5.4.1";
  };
  redis-client = {
    dependencies = ["connection_pool"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jw2xjzz24dwn85y8v1jf1vzzpsnypsvs06f1qfa91w7rpwr5248";
      type = "gem";
    };
    version = "0.28.0";
  };
  regexp_parser = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1fwfw26a32rps78920nn29shqg2zmqv72i89j1fap41isshida9m";
      type = "gem";
    };
    version = "2.12.0";
  };
  resolv = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1f4ld293xpqmjh8sgfrq375c7dnay4v43j169qgl1mk15abxbn97";
      type = "gem";
    };
    version = "0.7.1";
  };
  rexml = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hninnbvqd2pn40h863lbrn9p11gvdxp928izkag5ysx8b1s5q0r";
      type = "gem";
    };
    version = "3.4.4";
  };
  rspec = {
    dependencies = ["rspec-core" "rspec-expectations" "rspec-mocks"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11q5hagj6vr694innqj4r45jrm8qcwvkxjnphqgyd66piah88qi0";
      type = "gem";
    };
    version = "3.13.2";
  };
  rspec-core = {
    dependencies = ["rspec-support"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0bcbh9yv6cs6pv299zs4bvalr8yxa51kcdd1pjl60yv625j3r0m8";
      type = "gem";
    };
    version = "3.13.6";
  };
  rspec-expectations = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dl8npj0jfpy31bxi6syc7jymyd861q277sfr6jawq2hv6hx791k";
      type = "gem";
    };
    version = "3.13.5";
  };
  rspec-mocks = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0iqxmw0knjiz5nf6pgr8ihs6cjzh89f0ppj3fqiz8cvms79x6sh8";
      type = "gem";
    };
    version = "3.13.8";
  };
  rspec-support = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0z64h5rznm2zv21vjdjshz4v0h7bxvg02yc6g7yzxakj11byah06";
      type = "gem";
    };
    version = "3.13.7";
  };
  rubocop = {
    dependencies = ["json" "language_server-protocol" "lint_roller" "parallel" "parser" "rainbow" "regexp_parser" "rubocop-ast" "ruby-progressbar" "unicode-display_width"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ca5inh368d4l24a2v2nbd3p4xc6s0pqs91j27h226nh04zmyha4";
      type = "gem";
    };
    version = "1.86.1";
  };
  rubocop-ast = {
    dependencies = ["parser" "prism"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dahfpnzz63hyqxa03x8rypnrxzwyvh4i5a8ri34bzpnf3pg64j4";
      type = "gem";
    };
    version = "1.49.1";
  };
  ruby-lsp = {
    dependencies = ["language_server-protocol" "prism" "rbs"];
    groups = ["vscode"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0aa1mg6bdl23wgrxd98wycq3963jfpnh9z0yh976p9q03h01r81k";
      type = "gem";
    };
    version = "0.26.9";
  };
  ruby-progressbar = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cwvyb7j47m7wihpfaq7rc47zwwx9k4v7iqd9s1xch5nm53rrz40";
      type = "gem";
    };
    version = "1.13.0";
  };
  sequel = {
    dependencies = ["bigdecimal"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0saswmna49yvyclcx1a5rabjqhl3aawyhahsqm7p51f59hvj7gsi";
      type = "gem";
    };
    version = "5.103.0";
  };
  sorbet-runtime = {
    groups = ["vscode"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pfz6y6xpqpz1bf5xsdcxrdcwyi18wk86kkqi7gmx6ciigdk2779";
      type = "gem";
    };
    version = "0.6.13153";
  };
  sqlite3 = {
    dependencies = ["mini_portile2"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bj7dv3rqcs48s5zhlb9bypyfksfgwbxb42a1spzs6r4hwf8gjp5";
      type = "gem";
    };
    version = "2.9.3";
  };
  stringio = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1q92y9627yisykyscv0bdsrrgyaajc2qr56dwlzx7ysgigjv4z63";
      type = "gem";
    };
    version = "3.2.0";
  };
  tempfile = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0snpzrrwj7lc8a1fhqsml4kacc715bi4f88hndg50kkl8sv3md8b";
      type = "gem";
    };
    version = "0.3.1";
  };
  terminal-table = {
    dependencies = ["unicode-display_width"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1lh18gwpksk25sbcjgh94vmfw2rz0lrq61n7lwp1n9gq0cr7j17m";
      type = "gem";
    };
    version = "4.0.0";
  };
  time = {
    dependencies = ["date"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1arxpii25xgb3fkgqp5acyc0x6179j3qzld78lflgsdxqfcf897k";
      type = "gem";
    };
    version = "0.4.2";
  };
  tmpdir = {
    dependencies = ["fileutils"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gailccjj4gxghfkm7nwm1cgi9wkhby3rh3zl95i1kiipclrg3lh";
      type = "gem";
    };
    version = "0.3.1";
  };
  tsort = {
    groups = ["default" "vscode"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17q8h020dw73wjmql50lqw5ddsngg67jfw8ncjv476l5ys9sfl4n";
      type = "gem";
    };
    version = "0.2.0";
  };
  tzinfo = {
    dependencies = ["concurrent-ruby"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16w2g84dzaf3z13gxyzlzbf748kylk5bdgg3n1ipvkvvqy685bwd";
      type = "gem";
    };
    version = "2.0.6";
  };
  tzinfo-data = {
    dependencies = ["tzinfo"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1z896q8kzig9x6g3bcp38apns05y36jhf4j7ml7wzqjsmqcnb8sf";
      type = "gem";
    };
    version = "1.2026.1";
  };
  unicode-display_width = {
    dependencies = ["unicode-emoji"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hiwhnqpq271xqari6mg996fgjps42sffm9cpk6ljn8sd2srdp8c";
      type = "gem";
    };
    version = "3.2.0";
  };
  unicode-emoji = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03zqn207zypycbz5m9mn7ym763wgpk7hcqbkpx02wrbm1wank7ji";
      type = "gem";
    };
    version = "4.2.0";
  };
  uri = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ijpbj7mdrq7rhpq2kb51yykhrs2s54wfs6sm9z3icgz4y6sb7rp";
      type = "gem";
    };
    version = "1.1.1";
  };
  webrick = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ca1hr2rxrfw7s613rp4r4bxb454i3ylzniv9b9gxpklqigs3d5y";
      type = "gem";
    };
    version = "1.9.2";
  };
  win32ole = {
    groups = ["default"];
    platforms = [{
      engine = "mingw";
    } {
      engine = "mswin";
    } {
      engine = "mswin64";
    }];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15jdx4cd2g4spi50g2gad1cxiwr89a5m6kr0b1p6x00kvk2kvx01";
      type = "gem";
    };
    version = "1.9.3";
  };
  yaml = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hhr8z9m9yq2kf7ls0vf8ap1hqma1yd72y2r13b88dffwv8nj3i4";
      type = "gem";
    };
    version = "0.4.0";
  };
  zlib = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "084w64p55s3l2rmbs6x84qbclhi451n8n2limdj1mwrjidlidlsv";
      type = "gem";
    };
    version = "3.2.3";
  };
}
