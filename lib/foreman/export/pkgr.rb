require "erb"
require "foreman/export"

class Foreman::Export::Pkgr < Foreman::Export::Base

  def export
    super

    Dir["#{location}/#{app}*.conf"].each do |file|
      clean file
    end

    write_template "pkgr/master.conf.erb", "#{app}.upstart", binding

    engine.each_process do |name, process|
      next if engine.formation[name] < 1
      write_template "pkgr/process_master.conf.erb", "#{app}-#{name}.upstart", binding

      1.upto(engine.formation[name]) do |num|
        port = engine.port_for(process, num)
        write_template "pkgr/process.conf.erb", "#{app}-#{name}-#{num}.upstart", binding
      end
    end
  end
end
