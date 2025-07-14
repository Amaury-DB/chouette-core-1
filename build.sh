set -e

[ -f build.rc ] && source build.rc

case "$1" in
  "docker::bundler::install")
    bundle install --jobs 4 --retry 3
    ;;
  "docker::yarn::install")
    yarn install --frozen-lockfile
    ;;
  "docker::assets::precompile")
    bundle exec rake assets:precompile
    ;;
  *)
    echo "Unknown command: $1"
    exit 1
    ;;
esac
