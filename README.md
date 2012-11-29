# NOTICE:

This gem is not complete and should not be used in any Rails applications yet.

# MTGExtractor

MTGExtractor is a Ruby gem that can be used to create Magic: The Gathering based
applications.

## Installation

Configure your Gemfile:

    gem 'mtgextractor'

Install the gem:

    rails g mtgextractor

Run migrations:

    rake db:migrate

Populate your database with card data from Gatherer (this will take a while):

    rake mtgextractor:update_all_sets

## Updating your database

When a new set comes out, you can simply update your database for just that one
set. All you have to do is run a rake task and specify which set you want to
update.

    rake mtgextractor:update_set "Set Name"

