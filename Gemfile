source "https://rubygems.org"

# Pins Jekyll and every plugin to the exact versions GitHub Pages runs in
# production, so a local preview matches the live site.
gem "github-pages", group: :jekyll_plugins

# Ruby 3.x no longer bundles these; `jekyll serve` needs them locally.
gem "webrick"
gem "csv"
gem "base64"
gem "bigdecimal"
gem "logger"

# Windows has no zoneinfo database.
platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
