
Dir[File.expand_path('../plugins/*.rb', __FILE__)].each do |plug|
  require(plug)
end
