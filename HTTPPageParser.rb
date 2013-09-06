require 'mechanize'

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