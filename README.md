# NOTICE:

This gem is not complete and should not be used in any Rails applications yet.

# MTGExtractor

MTGExtractor is a Ruby gem that can be used to create Magic: The Gathering based
applications.

## Installation

Configure your Gemfile:

    gem 'mtgextractor'

Install the gem:

    bundle

Run the generator:

    rails g mtgextractor

Run migrations:

    rake db:migrate

## Updating your database

Populate your database with all cards for every set from Gatherer (this will take a while):

    RAILS_ENV=environment rake mtgextractor:update_all_sets

When a new set comes out, you can simply update your database for just that one
set. All you have to do is run a rake task and specify which set you want to
update.

    RAILS_ENV=environment SET="Set name" rake mtgextractor:update_set

Note: If you don't specify a RAILS_ENV, it will default to 'development'.
