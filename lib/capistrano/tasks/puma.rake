namespace :puma do
  %w(start stop restart).each do |command|
    desc "#{command} puma server"
    task command do
      on roles(:app), except: { no_release: true } do
        execute "/etc/init.d/puma #{command} /etc/puma/#{fetch(:application)}.conf"
      end
    end
  end
end
