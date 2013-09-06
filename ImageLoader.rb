require 'mechanize'

require 'thread'
require 'benchmark'

require './HTTPPageSocket.rb'
require './HTTPPageParser.rb'

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