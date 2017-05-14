class Track
  def initialize(response, client)
    @response =  response
    @client = client
  end

  def download_url
    # Api call to get track stream_url does not work as described in documentation
    # https://developers.soundcloud.com/docs/api/guide#playing
    #
    # Using 'fix' found here
    # https://github.com/soundcloud/soundcloud-ruby/issues/30
    begin
      @client.get(@response.stream_url, {}, follow_redirects: false)
    rescue ::Soundcloud::ResponseError => e
      return JSON.parse(e.response.body)["location"]
    end
  end

  #def image_url
  #  @response.artwork_url
  #end

  def name
    @response.permalink
  end

  def artist
    @response.user.username
  end
end