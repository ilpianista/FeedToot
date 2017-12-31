FeedToot
========

An RSS feed generator based on Mastodon toots.

## Options
    -t, --tag <tag>                  Fetch toots with this tag
    -l, --limit <n>                  Fetch at most N toots (default: 20)
    -u, --url <url>                  Mastodon instance URL (default: mastodon.social)
    -h, --help                       Show this help

## Example usage
    ruby feedtoot.rb -t mastodon

## Running
You need the bundler gem (`ruby`), then exec:

    $ git clone https://gitlab.com/ilpianista/FeedToot.git
    $ cd feedtoot
    $ gem install bundler
    $ bundle install
    $ ruby feedtoot.rb -h

## Donate

Donations via [Liberapay](https://liberapay.com/ilpianista) or Bitcoin (1Ph3hFEoQaD4PK6MhL3kBNNh9FZFBfisEH) are always welcomed, _thank you_!

## License

MIT
