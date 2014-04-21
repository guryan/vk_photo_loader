# coding: utf-8;
require 'headless'
require 'capybara'
require 'capybara-webkit'



@@headless = Headless.new
@@headless.start
@@session = Capybara::Session.new(:webkit)


ROOT_URL = "http://vk.com"


class Album
  ALBUM_SELECTOR = "#photos_albums_container > .photo_row"
  PHOTO_SELECTOR = "#photos_container > .photo_row"
  TITLE_AND_NUM_REGEXP = /([\s\!а-я]+)(\d+)/i
  AllAlbumsUrl = "#{ROOT_URL}/albums-49367366"
  LogoPicturesAlbumsId = "album-49367366_0"

  attr_accessor :id, :title, :photo_num, :photos
  class << self
    def load_from_session(session)
      @@session ||= session
      session.visit(AllAlbumsUrl)
      session.execute_script("photos.loadAlbums()")
      session.all(ALBUM_SELECTOR).inject([]) do |array, album_node|
        if album_node[:id] == LogoPicturesAlbumsId
          array
        else
          title_and_num = album_node.text.match(TITLE_AND_NUM_REGEXP)
          array << new(id: album_node[:id], title: title_and_num[1], photo_num: title_and_num[2].to_i)
        end
      end
    end
  end
  def initialize(options)
    @id = options[:id]
    @title = options[:title]
    @photo_num = options[:photo_num]
  end
  def photos_urls
    @@session.visit("#{ROOT_URL}/#{id}")
    @@session.all(PHOTO_SELECTOR).inject([]) {|array, photo_node| array << photo_node[:id].gsub("_row","") }
  end
  def photos
    @photos ||= Photo.load_from_urls(@@session, self, photos_urls)
  end
  def inspect
    "<#Album title: #{title} photos: #{photo_num}>"
  end
end

class Photo
  attr_accessor :id, :url, :description, :album
  def initialize(options)
    @id = options[:id]
    @url = options[:url]
    @description = options[:description]
    @album = options[:album]
  end
  class << self
    def load_from_urls(session, album, photo_urls)
      @@session ||= session
      photo_urls.map do |photo_url|
        @@session.visit("#{ROOT_URL}/#{photo_url}")
        session.execute_script("photos.load()")
        url = @@session.find("#pv_actions > a[target=_blank]")[:href]
        descr = @@session.find("#pv_desc").text rescue ""
        new(id: photo_url, url: url, description: descr, album: album)
      end
    end
  end
  def inspect
    "<#Photo #{url} #{description}>"
  end
end

@@albums = Album.load_from_session(@@session)

