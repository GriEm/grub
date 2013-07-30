require 'rubygems'
require 'mechanize'
require 'thread'

class ImageLoader	

    DEFAULT_THREAD_CNT = 2

    attr_accessor   :URL, :Folder
    attr_accessor   :Proxy, :User, :Password
    attr_accessor   :ThreadCnt
    attr_reader     :ImgList

    def initialize(&block)
        @ImgList    = []
        @ThreadCnt  = DEFAULT_THREAD_CNT

        instance_eval(&block)

        @URL    = @URL.gsub(" ","") if @URL != nil
        @Proxy  = @Proxy.gsub(" ","") if @Proxy != nil

        @agent = Mechanize.new do |a|
            if @Proxy
                a.set_proxy(
                                @Proxy[%r{.*:}].sub(":",""),
                                @Proxy[%r{[0-9]*$}],
                                @User,@Password
                ) rescue raise ArgumentError, "Proxy fail"
            end
        end
    end

    def load(url = nil, folder = nil)
        begin		
            setURL(url)
            setFolder(folder)

            startStat
            page = @agent.get(@URL)
            queueLoad(page)
            stopStat
        rescue
            puts "Load fail"
        end
    end

    private

    def startStat
        @StartTime = Time.new
    end

    def stopStat
        @StopTime = Time.new

        STDOUT.puts "\nLoad images from <#{@URL}> to <#{@Folder}>"
        STDOUT.puts "Count load images:   #{@ImgList.size}"
        STDOUT.puts "Load time(sec):      #{@StopTime - @StartTime}"
    end

    # если url == nil, то используется значение, указанное
    # при создании экземляра класса

    def setURL(url)
        @URL = url.gsub(" ","") if url != nil
        raise(ArgumentError,"URL fail") if @URL == nil or @URL.empty?
    end

    # если folder == nil, то все картинки сохраняются в
    # папку images, расположенную там же, где и grub.rb

    def setFolder(folder)
        @Folder = folder
        @Folder = "images" if folder == nil

        begin
            unless File::exist?(@Folder)
                Dir.mkdir(@Folder)
            end
        rescue
            raise RuntimeError, "Folder fail"
        end
    end

    def getImageFileName(image)
        img_name = @Folder + "/" + image.url.to_s.split("/").last

        if img_name.include?("?")
            img_name.gsub!("?","_")
            img_name << image.extname
        end

        return img_name
    end

    def getAndSaveImage(queue)
        image = queue.pop
        fileName = getImageFileName(image)

        unless image.extname == ""
            Thread::exclusive {
                unless File::exists?(fileName)
                    @ImgList << fileName
                    image.fetch.save(fileName)
                end
            }
        end
    end	

    # картинки помещаются в очередь на загрузку
    # затем @ThreadCnt потоков обрабатывают эту очередь

    def queueLoad(page)
        queueImages = Queue.new

        page.images.each do |image|
            queueImages << image
        end

        threads = []
        
        @ThreadCnt.times do
            threads << Thread.new { getAndSaveImage(queueImages) while not queueImages.empty? }
        end

        threads.each { |thread| thread.join }
    end
end