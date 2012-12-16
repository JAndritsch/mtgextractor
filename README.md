# NOTICE:

This gem is not complete and should not be used in any Rails applications yet.

# MTGExtractor

MTGExtractor is a Ruby gem that can be used to create Magic: The Gathering based
applications. Because there is no public API for accessing MTG card data, we've
put togther a Ruby gem that allows you to build your own Magic: The Gathering
data source.

This gem can help you create an entire database of every MTG card, set, and so on.
It works by scraping the Gatherer web site (http://gatherer.wizards.com) for
card data.

Rails applications that use this gem will be able to:

  - Have their own database of MTG cards and MTG-related information
  - Have automatically generated ActiveRecord models available to their application
  that allow them access to the data
  - Have access to simple rake tasks for updating the database whenever new sets release

## Installation

Configure your Gemfile:

    gem 'mtgextractor'

Install the gem:

    bundle

Run the generator to generate the migrations and models:

    rails g mtgextractor

Run migrations to create the tables:

    rake db:migrate

## Updating your database

### Getting all cards and all sets

Populate your database with all cards for every set from Gatherer (this will take a while):

    RAILS_ENV=environment rake mtgextractor:update_all_sets

Optionally, you can begin processing all sets starting from a different position in the list.
The list of sets is dynamically acquired and sorted alphabetically. If you've already processed
all sets starting from Alara Reborn to Apocalypse, you can start this task over and begin the 
processing at the next set after Apocalypse (Arabian Nights). 

To do this, you can run this command:

    RAILS_ENV=environment START="Arabian Nights" rake mtgextractor:update_all_sets

Doing this will ignore processing all sets that come before Arabian Nights in the list.

### Processing one set at a time 

When a new set comes out, you can simply update your database for just that one
set. All you have to do is run a rake task and specify which set you want to
update.

    RAILS_ENV=environment SET="Set name" rake mtgextractor:update_set

Note: If you don't specify RAILS_ENV, it will default to 'development'.


### Card and set images

When processing a set, MTGExtractor will download all the card images and all icons for the
set. The location of these images will depend on the version and configuration of your Rails 
application.

MTGExtractor supports the asset pipeline and will store your images in the following location
if the asset pipeline is enabled:

    app/assets/images/

If you've configured the asset pipeline to use a different prefix other than "assets", MTGExtractor
will use that prefix automatically.

For applications that don't use the asset pipeline, you will find your card and set images here:

    public/images/

Once you've completed processing a set, you will have a directory structure similar to this:
(Assuming the asset pipeline is enabled)

    app/
      assets/
        images/
          innistrad/
            - 22343.jpg (The numbers match to a card's multiverse id)
            - 39284.jpg
            - common_icon.jpg (Used for displaying the card's icon)
            - uncommon_icon.jpg
   
## Accessing your card data

After you run the generator and updated your database, you will have access to
the following ActiveRecord models in your Rails application:

  - **MtgCard**: Contains card attributes like name, mana cost, oracle text...
  - **MtgSet**: A set, such as "Innistrad".
  - **MtgType**: A card type, like "Land", "Instant", "Human", "Creature", etc...
  - **MtgCardType**: An associative class that bridges the many-to-many relationship between MtgCard and MtgType.

### MtgCard

This model provides you with a way to access an individual card. It contains the following attributes:

    :name
    :gatherer_url
    :multiverse_id
    :gatherer_image_url
    :mana_cost
    :converted_cost
    :oracle_text
    :flavor_text
    :mark
    :power
    :toughness
    :loyalty
    :rarity
    :transformed_id
    :colors
    :artist

MtgCard also has a couple convenience methods:

  - transformed_side: Returns a new MtgCard object that is the transformed side of the current card. If
  the card does not transform, nil is returned.
  - image_url: Returns the URL for where the card's local image is stored. 
  - set_symbol_url: Returns the URL for the card's set symbol.

Additionally, MtgCard has several relationships to other models. The relationships are:

  - MtgCard belongs to MtgSet.
  - MtgCard has many MtgTypes

You can access a card's set and types through ActiveRecord relations. These relationships are already
set up and can be used as follows:

    some_card  = MtgCard.first
    set_name   = some_card.set     # An MtgSet object that responds to :name
    types      = some_card.types   # An array of MtgType objects that responds to :name

### MtgSet

This class models after an MTG set and has the following attributes:

    :name

MtgSet also has a few convenience methods:

  - folder_name: Returns the name of the folder that all the card and set images will be found.
  The folder name is a slugified version of the set name. 

The remaining methods simply return the local path to the set's icon for each different rarity type.

  - common_icon:
  - uncommon_icon:
  - rare_icon:
  - mythic_icon:
  - special_icon:
  - promo_icon:
  - land_icon:

The relationships for MtgSet are:

  - MtgSet has many MtgCards

This relationship allows you to ask a set for all of its cards:

    some_set      = MtgSet.first
    cards_for_set = some_set.cards # An array of MtgCard objects

### MtgType

The last useful class is MtgType, which models after a card type (such as "Instant") and
has the following attributes:

    :name

A relationship exists between MtgCard and MtgType, which looks like this:

  - MtgType has many MtgCards

Because MtgCard also has many MtgTypes, the MtgCardType class exists to bridge that many-to-many
relationship. Having this relationship allows you to ask an MtgType for all cards that have that
type:

    some_type          = MtgType.first
    cards_of_that_type = some_type.cards  # An array of MtgCard objects


## As a standalone gem

MTGExtractor does not have to be used in a Rails application solely, however most
of the work on this gem has been towards achieving that goal. If you wish to use
this gem as a standalone tool, you can simply make use of the classes that scrape
the Gatherer web site and return data.

Those classes are:

**MTGExtractor::SetExtractor**: Returns a list of URLs for each card in provided
set. These URLs point to each individual card's details page. Example:

    require 'mtgextractor'
    set_extractor = MTGExtractor::SetExtractor.new("Innistrad")
    all_cards_in_set = set_extractor.get_card_urls

**MTGExtractor::CardExtractor**: Returns a hash of card data when given the
URL for a card details page. Example:

    require 'mtgextractor'
    black_lotus_url = 'http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=600'
    card_extractor = MTGExtractor::CardExtractor.new(black_lotus_url)
    black_lotus_data = card_extractor.get_card_details

## Support

### Ruby

MTGExtractor has been tested against the following Ruby versions:

  - MRI 1.8.7+
  - JRuby 1.6 with MRI 1.8.7
  - JRuby 1.7 with MRI 1.9

**Note**: You will need Iconv for MRI 1.8.7


### Rails

MTGExtractor has been tested against the following Rails versions:

  - 3.2.6
