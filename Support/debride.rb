#!/usr/bin/env ruby

begin
  require 'debride'
  require 'json'
rescue LoadError
  puts "Install debride!\ngem install debride"
  exit 1
end

def log(msg)
  require 'logger'
  logger = Logger.new('/tmp/debride_bundle.log')
  logger.info msg
end

def offences(file)
  whitelist = ENV['RUBY_WHITELIST']
  @bad = []
  debride = if whitelist
    Debride.run(['--whitelist', whitelist, file])
  else
    Debride.run([file])
  end
  debride.missing.each do |klass, meths|
    bad = meths.map { |meth|
      location = debride.method_locations["#{klass}##{meth}"] || debride.method_locations["#{klass}::#{meth}"]
      line = location[/.*:(\d+)$/, 1]
      path = location[/(.+):\d+$/, 1]
      [location]
    }
    bad.compact!
    next if bad.empty?
    @bad = bad
  end
  @bad
end

def messages(offences)
  messages = {
    warning: {}
  }
  offences.each do |offence|
    severity = :warning
    line = offence[0][/.*:(\d+)$/, 1]
    message = messages[severity][line] ||= []
    message << "This method MIGHT not be called."
  end
  messages
end

def command(messages)
  icons = {
    warning:    "#{ENV['TM_BUNDLE_SUPPORT']}/bride.png".inspect
  }
  args = []

  messages.each do |severity, messages|
    args << ["--clear-mark=#{icons[severity]}"]
    messages.each do |line, message|
      args << "--set-mark=#{icons[severity]}:#{message.uniq.join('. ').inspect}"
      args << "--line=#{line}"
    end
  end

  args << ENV['TM_FILEPATH'].inspect

  "#{ENV['TM_MATE']} #{args.join(' ')}"
end

cmd = command(messages(offences(ENV['TM_FILEPATH'])))

# log cmd
exec cmd
