{ bundix }:

# bundix 2.5.2 predates Bundler's :windows platform alias. Preserve the
# upstream Gemfile and map Windows-only gems to non-MRI engines for filtering.
bundix.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    substituteInPlace lib/bundix.rb \
      --replace-fail 'PLATFORM_MAPPING = {}' \
        'PLATFORM_MAPPING = { "windows" => [{engine: "mswin"}, {engine: "mswin64"}, {engine: "mingw"}] }'
    # Cached hashes are reusable, but groups/platforms must follow the Gemfile
    # even when upstream leaves a gem's version unchanged.
    substituteInPlace lib/bundix.rb \
      --replace-fail '      gems.merge!(gem)' \
        '      gem[spec.name] = gem[spec.name].transform_keys(&:to_s)
      gem[spec.name]["groups"] = groups(spec, dep_cache)[:groups]
      gem[spec.name]["platforms"] = platforms(spec, dep_cache)[:platforms]
      gems.merge!(gem)'
  '';
})
