namespace :unicorn do
  %w(start stop restart).each do |command|
    desc "#{command} unicorn server"
    task command do
      on roles(:app), except: { no_release: true } do
        execute "/etc/init.d/unicorn #{command} /etc/unicorn/#{fetch(:application)}.conf"
      end
    end
  end
end
