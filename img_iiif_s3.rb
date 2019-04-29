require 'iiif_s3'
require 'open-uri'
require_relative 'lib/iiif_s3/manifest_override'
IiifS3::Manifest.prepend IiifS3::ManifestOverride

# path to the image files end with "obj_id/image.tif" 
@dir_url = "https://img.cloud.lib.vt.edu/Ms1990_057_Chadeayne/Edited/Ms1990_057_Box1/Ms1990_057_B001_F001_001_LHJClips_Ms/Access"
@csv_url = "https://scholar-jekyll.dev.vtlibcloud.com/iiftest/Chadeayne_Ms1990_057_Box1.csv"
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

# Create directories on local disk for manifests/tiles to upload them to S3
def create_directories(path)
  FileUtils.mkdir_p(path) unless Dir.exists?(path)
end

# Get label and description metadata from csv file
def get_metadata(csv_url, id)
  begin
    open(csv_url) do |u|
      csv_file_name = File.basename(csv_url)
      csv_file_path = "#{@config.output_dir}/#{csv_file_name}"
      unless File.exists?(csv_file_path)
        File.open(csv_file_path, 'wb') { |f| f.write(u.read) }
      end
      CSV.read(csv_file_path, 'r:bom|utf-8', headers: true).each do |row|
        if row.header?("Identifier")
          if row.field("Identifier") == id
            return row.field("Title"), row.field("Description")
          end
        else
          puts "No Identifier header found"
          return
        end
      end
      puts "No matching Identifier found"
    end
  rescue
    puts "No CSV file found"
  end
end

def add_image(file, id)
  # name should be either as numerical or identifier_numerical,
  # such as Ms1990_025_Per_Awd_B001_F001_006_001.tif or 001.tif
  name = File.basename(file, File.extname(file))
  page_num = name.split("_").last.to_i
  label, description = get_metadata(@csv_url, id)
  obj = {
    "path" => "#{file}",
    "id"       => id,
    "label"    => label,
    "is_master" => page_num == 1,
    "page_number" => page_num,
    "is_document" => false,
    "description" => description,
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
create_directories(path)
# generate a path on disk for "output_dir/prefix/image_dir"
img_dir = "#{path}#{@config.image_directory_name}/".split("/")[0...-1].join("/")
create_directories(img_dir)

id = @dir_url.split("/")[-2]
# write originial images to disk
file_dir = "#{@config.output_dir}/#{id}"
create_directories(file_dir)
# We don't have access permission to the bucket, so just enumerate all the files
  
img_file_base_name = "#{id}_001"
img_file = "#{img_file_base_name}.tif"
img_file_path = "#{@config.output_dir}/#{id}/#{img_file}"
# image object as s3 link
url = "#{@dir_url}/#{img_file}"
can_open = true
while can_open 
  begin	
    open(url) do |u|
      File.open(img_file_path, 'wb') { |f| f.write(u.read) }
      add_image(img_file_path, id)
      img_file_base_name = img_file_base_name.next
      img_file = "#{img_file_base_name}.tif"
      img_file_path = "#{@config.output_dir}/#{id}/#{img_file}"
      url = "#{@dir_url}/#{img_file}"
      can_open = false if img_file_base_name == "#{id}_003"
    end
  rescue
    can_open = false
  end
end
iiif.load(@data)
iiif.process_data
