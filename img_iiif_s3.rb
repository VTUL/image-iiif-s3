require 'iiif_s3'
require 'open-uri'
require_relative 'lib/iiif_s3/manifest_override'
IiifS3::Manifest.prepend IiifS3::ManifestOverride

# path to the image files end with "obj_id/image.tif" 
@dir_url = "https://img.cloud.lib.vt.edu/Ms1990_057_Chadeayne/Edited/Ms1990_057_Box1/Ms1990_057_B001_F001_001_LHJClips_Ms/Access"
# Setup Temporary stores
@data = []
# Set up configuration variables
opts = {}
opts[:image_directory_name] = "tiles"
opts[:output_dir] = "tmp"
opts[:variants] = { "reference" => 600, "access" => 1200}
opts[:upload_to_s3] = true
opts[:image_types] = [".jpg", ".tif", ".jpeg", ".tiff"]
opts[:document_file_types] = [".pdf"]
opts[:prefix] = "iiif_s3_test/#{@dir_url.split('/')[3..-3].join('/')}"

def add_image(file, id)
  # name should be either as numerical or identifier_numerical,
  # such as Ms1990_025_Per_Awd_B001_F001_006_001.tif or 001.tif
  name = File.basename(file, File.extname(file))
  page_num = name.split("_").last.to_i

  obj = {
    "path" => "#{file}",
    "id"       => id,
    "label"    => "Certificate and program for YWCA Leader Luncheon VI, March 27, 1980 (Ms1990-025)",
    "is_master" => page_num == 1,
    "page_number" => page_num,
    "is_document" => false,
    "description" => "Leader Luncheon certificate of achievement honoring the leadership of women in the economic, civic, and cultural life of Los Angeles. Lorraine Rudoff's name appears on page 8 of the luncheon program.",
    "attribution" => "Special Collections, University Libraries, Virginia Tech",
  }  

  obj["section"] = "p#{page_num}"
  obj["section_label"] = "Page #{page_num}"
  @data.push IiifS3::ImageRecord.new(obj)
end

iiif = IiifS3::Builder.new(opts)
@config = iiif.config
# generate a path on disk for "output_dir/prefix/id" 
path = "#{@config.output_dir}#{@config.prefix}/"
FileUtils.mkdir_p(path) unless Dir.exists?(path)
# generate a path on disk for "output_dir/prefix/image_dir"
img_dir = "#{path}#{@config.image_directory_name}/".split("/")[0...-1].join("/")
FileUtils.mkdir_p(img_dir) unless Dir.exists?(img_dir)

id = @dir_url.split("/")[-2]
# write originial images to disk
file_dir = "#{@config.output_dir}/#{id}"
Dir.mkdir(file_dir) unless Dir.exists?(file_dir)
# We don't have access permission to the bucket, so just enumerate all the files
  
file_base_name = "#{id}_001"
file = "#{file_base_name}.tif"
file_path = "#{@config.output_dir}/#{id}/#{file}"
# image object as s3 link
url = "#{@dir_url}/#{file}"
can_open = true
while can_open 
  begin	
    open(url) do |u|
      File.open(file_path, 'wb') { |f| f.write(u.read) }
      image_record = add_image(file_path, id)
      file_base_name = file_base_name.next
      file = "#{file_base_name}.tif"
      file_path = "#{@config.output_dir}/#{id}/#{file}"
      url = "#{@dir_url}/#{file}"
      can_open = false if file_base_name == "#{id}_002"
    end
  rescue
    can_open = false
  end
end
iiif.load(@data)
iiif.process_data
