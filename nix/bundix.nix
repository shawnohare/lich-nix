{ bundix }:

# bundix 2.5.2 predates Bundler's :windows platform alias. Preserve the
# upstream Gemfile and map Windows-only gems to non-MRI engines for filtering.
bundix.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    substituteInPlace lib/bundix.rb \
      --replace-fail 'PLATFORM_MAPPING = {}' \
        'PLATFORM_MAPPING = { "windows" => [{engine: "mswin"}, {engine: "mswin64"}, {engine: "mingw"}] }'
  '';
})
