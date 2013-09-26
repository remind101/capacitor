namespace :capacitor do
  task :run => :environment do
    Capacitor.run
  end
end
