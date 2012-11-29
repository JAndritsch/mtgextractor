# These tasks are for setting up a Rails application only
if defined?(Rails)

  namespace 'mtgextractor' do
    desc 'Extracts every card in every set from Gatherer and saves it to the DB'
    task :update_all_sets do
      # Pending
    end

    desc 'Extracts every card in provided set from Gatherer and saves it to the DB'
    task :update_set do
      # Pending
    end
  end

end
