require 'headless'
require 'capybara'
require 'capybara-webkit'

RootUrl = "http://vk.com"
AllAlbumsUrl = "#{RootUrl}/albums-49367366"
LogoPicturesAlbumsId = "album-49367366_0"

@@headless = Headless.new
@@headless.start
@@session = Capybara::Session.new(:webkit_debug)
@@session.visit(AllAlbumsUrl)
@@session.execute_script("photos.loadAlbums()")
@@albums_paths = @@session.all("#photos_albums_container > .photo_row").inject([]) do |array, node|
  node[:id] == LogoPicturesAlbumsId ? array : array << node[:id]
end
@@photo_paths = @@albums_paths.inject({}) do |hash, album_path|
  @@session.visit("#{RootUrl}/#{album_path}")
  photo_paths = @@session.all("#photos_container > .photo_row").inject([]) {|array, photo_node| array << photo_node[:id].gsub("_row","") }
  hash.merge(album_path => photo_paths)
end

@@photo_urls = @@photo_paths.each_pair.inject({}) do |hash, (album_path,photos_paths)|
  photos_urls = photos_paths.inject([]) do |array, photo_path|
    @@session.visit("#{RootUrl}/#{photo_path}")
    array << @@session.find("#pv_actions > a[target=_blank]")[:href]
  end
  hash.merge(album_path => photos_urls)
end