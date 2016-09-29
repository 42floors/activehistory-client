require 'uri'
require 'net/https'

class ActiveCortex::Connection
  
  attr_reader :api_key, :host, :port, :ssl
  
  def initialize(config)
    if config[:url]
      uri = URI.parse(config.delete(:url))
      config[:api_key] ||= (uri.user ? CGI.unescape(uri.user) : nil)
      config[:host]    ||= uri.host
      config[:port]    ||= uri.port
      config[:ssl] ||= (uri.scheme == 'https')
    end

    [:api_key, :host, :port, :ssl, :user_agent].each do |key|
      self.instance_variable_set(:"@#{key}", config[key])
    end

    @connection = Net::HTTP.new(host, port)
    @connection.use_ssl = ssl

    true
  end
  
  def user_agent
    [
      @user_agent,
      "Sunstone/#{ActiveCortex::VERSION}",
      "Ruby/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
      RUBY_PLATFORM
    ].compact.join(' ')
  end
  
  def post(path, body=nil, &block)
    request = Net::HTTP::Post.new(path)

    send_request(request, body, &block)
  end
  
  def url
    "http#{ssl ? 's' : ''}://#{host}#{port != 80 ? (port == 443 && ssl ? '' : ":#{port}") : ''}"
  end
  
  def send_request(request, body=nil, &block)
    request['Accept'] = 'application/json'
    request['User-Agent'] = user_agent
    request['Api-Key'] = api_key
    request['Content-Type'] = 'application/json'
    
    if body.is_a?(IO)
      request['Transfer-Encoding'] = 'chunked'
      request.body_stream =  body
    elsif body.is_a?(String)
      request.body = body
    elsif body
      request.body = JSON.generate(body)
    end

    return_value = nil
    retry_count = 0
    begin
      @connection.request(request) do |response|
        if response['API-Version-Deprecated']
          logger.warn("DEPRECATION WARNING: API v#{API_VERSION} is being phased out")
        end

        validate_response_code(response)

        # Get the cookies
        response.each_header do |key, value|
          if key.downcase == 'set-cookie' && Thread.current[:sunstone_cookie_store]
            Thread.current[:sunstone_cookie_store].set_cookie(request_uri, value)
          end
        end

        if block_given?
          return_value =yield(response)
        else
          return_value =response
        end
      end
    rescue ActiveRecord::ConnectionNotEstablished
      retry_count += 1
      retry_count == 1 ? retry : raise
    end

    return_value
  end
  
  def validate_response_code(response)
    code = response.code.to_i

    if !(200..299).include?(code)
      case code
      when 400
        raise ActiveCortex::Exception::BadRequest, response.body
      when 401
        raise ActiveCortex::Exception::Unauthorized, response
      when 404
        raise ActiveCortex::Exception::NotFound, response
      when 410
        raise ActiveCortex::Exception::Gone, response
      when 422
        raise ActiveCortex::Exception::ApiVersionUnsupported, response
      when 503
        raise ActiveCortex::Exception::ServiceUnavailable, response
      when 301
        raise ActiveCortex::Exception::MovedPermanently, response
      when 502
        raise ActiveCortex::Exception::BadGateway, response
      when 300..599
        raise ActiveCortex::Exception, response
      else
        raise ActiveCortex::Exception, response
      end
    end
  end
  
end