require 'sinatra'
require 'json'
require 'net/http'
require 'open-uri'
#require 'taglib'
require 'mustache/sinatra'
require "id3"
#require 'id3'

class Download < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'


  set :mustache, {
    :views     => 'views/',
    :templates => 'templates/'
  }
  
  
  get '/' do
    @notification = ""
    mustache :index
  end

  get '/download/:url' do
    client_id = ENV['SOUNDCLOUD_API']
  
    #pass in the url to the song and resolve it to get the song ID
    url = "http://api.soundcloud.com/resolve.json?url=#{params[:url]}&client_id=#{client_id}"
    resp = Net::HTTP.get_response(URI.parse(url))
    data = resp.body
    result = JSON.parse(data)
    if result.has_key? 'Error'
       raise "web service error"
    end
  
    #take the location and get the real song info
    resp2 = Net::HTTP.get_response(URI.parse(result["location"]))
    data2 = resp2.body
    song_info = JSON.parse(data2)
    #puts song_info
    if song_info.has_key? 'Error'
       raise "web service error"
    end
  
    if song_info["downloadable"] == true
      #follow the stram url and the redirect to the amazon asset
      URL = "#{song_info["download_url"]}?client_id=#{client_id}"
      open(URL) do |resp|
        dl = resp.base_uri.to_s
        filename = File.dirname(__FILE__) + "/tmp/#{song_info["permalink"]}.mp3"
        open(filename, 'wb') do |file|
          file << open(dl).read #save the file from amazon to computer
        end
        #open the file and add id3 tags
        if ! ID3::has_id3v2_tag?( filename )  
           # myfile = AudioFile.open( filename ) # do we need a new here?
           # 
           # myfile.id3v2tag["COMMENT"] = "Tilo's MP3 collection" # set the comment
           # 
           # 
           # myfile.write # writes to the same filename, overwriting the old file
           # myfile.close
           
           
           
           myfile = AudioFile.open( filename ) # do we need a new here?

           newtag = ID3v2tag("2.3.0") # create a new,empty v2 tag
           newtag["TITLE"] = song_info["title"] #set the song title
           newtag["ARTIST"] = song_info["user"]["username"] #set the song artist

           newtag.options["PADDINGSIZE"] = 0

           myfile.id3v2tag = newtag # assoziate the new tag with the AudioFile..
                                            # NOTE: we should CHECK when assigning a tag,
                                            # that the version number matches!

           myfile.write(filename) # if we overwrite, we should save the old tag in "filename.oldtag"
           myfile.close
        end
        
        
        
        
        # file = TagLib::MPEG::File.new(filename)
        # tag = file.id3v2_tag
        # tag.artist = artist = song_info["user"]["username"] #set the song artist
        # tag.title = song_info["title"] #set the song title
        # file.save
        # file.close
        send_file(filename, :disposition => 'attachment', :filename => File.basename(filename))
      end
    else
      redirect to('/no-download')
      redirect '/no-download', :notice => 'redirect with 301 code'
    end
  
  end
  
  get '/no-download' do
    @notification = '<div class="alert alert-danger"><strong>Alert</strong> This song is not available for download.</div>'
    mustache :index
  end
end