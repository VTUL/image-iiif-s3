require 'iiif_s3'
require 'open-uri'
require_relative 'lib/iiif_s3/manifest_override'
IiifS3::Manifest.prepend IiifS3::ManifestOverride

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

if ARGV.length != 2
  puts "Usage: ruby create_iiif_s3.rb csv_metadata_file image_folder_path"
  exit
end

@csv_url = ARGV[0]
# path to the image files end with "obj_id/image.tif" 
@input_folder = ARGV[1]

# read files in the input_folder
@image_files = Dir[@input_folder + "*"].sort

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
opts[:prefix] = "#{@input_folder.split('/')[1..-3].join('/')}"

iiif = IiifS3::Builder.new(opts)
@config = iiif.config

path = "#{@config.output_dir}#{@config.prefix}/"
create_directories(path)

# generate a path on disk for "output_dir/prefix/image_dir"
img_dir = "#{path}#{@config.image_directory_name}/".split("/")[0...-1].join("/")
create_directories(img_dir)

id = @input_folder.split("/")[-2]

for image_file in @image_files
  add_image(image_file, id)
end

iiif.load(@data)
iiif.process_data
