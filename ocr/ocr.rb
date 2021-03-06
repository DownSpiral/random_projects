require 'tesseract'

engine = Tesseract::Engine.new do |config|
  config.language  = :eng
  config.blacklist = '|'
end

def clean(text)
  text.split(/\n/).compact.select { |v| v.size > 0 }
end

puts clean(engine.text_for(ARGV.first))

