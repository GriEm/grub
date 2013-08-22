require 'mechanize'
require 'thread'
require 'benchmark'

class ImageLoader

    class FolderError < StandardError
    end

    class SaveFileError < StandardError
    end

    DEFAULT_THREAD_CNT  = 2
    DEFAULT_FOLDER      = 'images'

    attr_reader     :url, :folder
    attr_accessor   :thread_cnt
    attr_reader     :img_cnt

    def initialize(proxy = nil, user = nil, psw = nil)

        @url        = ""
        @folder     = DEFAULT_FOLDER
        @thread_cnt = DEFAULT_THREAD_CNT
        @img_cnt    = 0

        @http   = HTTPPageSocket.new(proxy, user, psw)
        @parser = HTTPPageParser.new

    end

    def load(url, folder = nil)

        @url        = url
        @folder     = (folder.nil? || folder.empty?) ? DEFAULT_FOLDER : folder
        @img_cnt    = 0

        open_folder(@folder)

        @open_time = Benchmark.measure { @page = @http.open(@url) }
        @pars_time = Benchmark.measure { @queue_images = @parser.get_images(@page) }
        @load_time = Benchmark.measure { thread_load(@queue_images) }

        print_log

    end

    private

    def print_log
        puts
        puts "URL:".ljust(15)           + @url
        puts "Folder:".ljust(15)        + @folder
        puts "Load images:".ljust(15)   + @img_cnt.to_s
        puts
        puts "Time execute (sec)"
        puts
        puts " "*7 + Benchmark::Tms::CAPTION
        puts "open".ljust(7) + @open_time.to_s
        puts "parsing".ljust(7) + @pars_time.to_s
        puts "load".ljust(7) + @load_time.to_s
    end

    def open_folder(folder)
        begin
            Dir.mkdir(folder) unless File::exist?(folder)
        rescue
            raise FolderError
        end
    end

    def get_and_save_image(queue)
        begin
            image       = queue.pop
            file_name   = @folder + "/" + image[:NAME]

            Thread::exclusive {
                unless File.exist?(file_name)
                    image[:SRC].fetch.save(file_name)
                    @img_cnt += 1
                end
            }
        rescue
            raise SaveFileError
        end
    end

    def thread_load(queue)
        threads = []
        @thread_cnt.times do
            threads << Thread.new {
                while !queue.empty?
                    get_and_save_image(queue)
                end
            }
        end

        threads.each { |thread| thread.join }
    end
end

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

class HTTPPageParser

    class GetImageError < StandardError
    end

    attr_reader :images
    
    def initialize
        @images = Queue.new
    end

    # create queue from hash literal items [:SRC => Mechanize::Image, :NAME => File name]

    def get_images(page)
        @images.clear

        begin
            page.images.each do |image|
                unless image.extname.empty?
                    @images << { :SRC => image, :NAME => get_image_name(image) }
                end
            end
        rescue
            raise GetImageError
        end

        @images
    end

    private

    def get_image_name(image)
        image_name = image.url.to_s.split("/").last

        if image_name.include?("?")
            image_name.gsub!("?","_")
            image_name << image.extname
        end

        image_name
    end

end