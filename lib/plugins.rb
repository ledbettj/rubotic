
Dir[File.expand_path('../plugins/*.rb', __FILE__)].each do |plug|
  puts plug
  require(plug)
end
