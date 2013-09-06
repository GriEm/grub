require 'mechanize'

class HTTPPageSocket

  class ProxyError < StandardError
  end

  class URLError < StandardError
  end

  class GetPageError < StandardError
  end

  attr_reader :proxy, :user, :psw
  attr_reader :url

  def initialize(proxy = nil, user = nil, psw = nil)

    # proxy is string like 'server:8080'

    @proxy = proxy.gsub(" ","") unless proxy.nil?
    @user, @psw = user, psw

    @agent = Mechanize.new do |a|
      if @proxy
        a.set_proxy(
          @proxy[%r{.*:}].sub(":",""),    # server
          @proxy[%r{[0-9]*$}],            # port
          @user, @psw
        ) rescue raise ProxyError
      end
    end
  end

  def open(url)
    raise URLError if url.nil? || url.empty?
    @url = url.gsub(" ","")
    @agent.get(@url) rescue raise GetPageError
  end

end