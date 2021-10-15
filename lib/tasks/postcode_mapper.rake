REGION_CODES = {
  'E12000001' => :north_east,
  'E12000002' => :north_west,
  'E12000003' => :yorkshire_and_the_humber,
  'E12000004' => :east_midlands,
  'E12000005' => :west_midlands,
  'E12000006' => :eastern,
  'E12000007' => :london,
  'E12000008' => :south_east,
  'E12000009' => :south_west,
  'W99999999' => :wales,
  'S99999999' => :scotland,
  'N99999999' => :northern_ireland,
  'L99999999' => :channel_islands,
  'M99999999' => :isle_of_man,
}

namespace :postcode_mappings do
  desc 'Generate mappings'
  task generate: :environment do
    pairs = []

    Dir['/Users/steve/Downloads/NSPL_AUG_2021_UK/Data/multi_csv/*.csv'].each do |file_name|
      puts "Processing #{file_name}"
      csv_data = CSV.parse(File.read(file_name), headers: true)
      pairs.concat(
        csv_data.map do |row|
          postcode = row['pcds']
          postcode ? [postcode.split[0], REGION_CODES[row['rgn']]] : nil
        end.compact.uniq.select { |postcode, region| postcode.present? && region.present? },
      )
    end
    File.open(Rails.root.join('config/initializers/postcode_to_region.rb'), 'w+') do |f|
      f.puts('POSTCODE_REGION_MAPPINGS = {')
      pairs.to_h.each do |postcode, region|
        f.puts("  '#{postcode}' => '#{region}',")
      end
      f.puts('}.freeze')
    end
  end
end
