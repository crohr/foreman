require "foreman/export"

class Foreman::Export::Pkgr < Foreman::Export::Base

  def export
    error("Must specify a location") unless location

    inittab = []
    inittab.push <<HEADER
#
### BEGIN INIT INFO
# Provides:          #{app}
# Required-Start:    $network $local_fs
# Required-Stop:
# Should-Start:      $named
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Launch #{app}
### END INIT INFO
#
HEADER
    inittab << "# ----- pkgr #{app} processes -----"

    index = 1
    engine.each_process do |name, process|
      1.upto(engine.formation[name]) do |num|
        id = app.slice(0, 2).upcase + sprintf("%02d", index)
        port = engine.port_for(process, num)

        commands = []
        commands << "cd #{engine.root}"
        commands << "source /etc/default/#{app}"
        engine.env.each_pair do |var, env|
          commands << "export #{var.upcase}=#{shell_quote(env)}"
        end
        commands << "#{process.command} >> #{log}/#{name}-#{num}.log 2>&1"

        inittab << "#{id}:4:respawn:/bin/su - #{user} -c '#{commands.join(";")}'"
        index += 1
      end
    end

    inittab << "# ----- end pkgr #{app} processes -----"

    inittab = inittab.join("\n") + "\n"

    if location == "-"
      puts inittab
    else
      say "writing: #{location}"
      File.open(location, "w") { |file| file.puts inittab }
    end
  end

end
