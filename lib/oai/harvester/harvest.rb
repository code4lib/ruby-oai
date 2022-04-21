#
#  Created by William Groppe on 2006-11-03.

module OAI
  module Harvester
    class Harvest
      DIRECTORY_LAYOUT = "%Y/%m".freeze
    
      def initialize(config = nil, directory = nil, date = nil, to = nil)
        @config = config || Config.load
        @directory = directory || @config.storage
        @from = date
        @from.freeze
        @until = to
        @until.freeze
        @parser = defined?(XML::Document) ? 'libxml' : 'rexml'
      end
    
      def start(sites = nil, interactive = false)
        @interactive = interactive
        sites = (@config.sites.keys rescue {}) unless sites
        begin
          sites.each do |site|
            harvest(site)
          end
        ensure
          @config.save
        end
      end
    
      private
    
      def harvest(site)
        opts = build_options_hash(@config.sites[site])
        if @until
          harvest_time = @until.to_time.utc
        else
          harvest_time = Time.now.utc
        end

        if OAI::Const::Granularity::LOW == granularity(opts[:url])
          opts[:until] = harvest_time.strftime("%Y-%m-%d")
          opts[:from] = @from.strftime("%Y-%m-%d") if @from
        else
          opts[:until] = harvest_time.xmlschema
          opts[:from] = @from.xmlschema if @from
        end

        # Allow a from date to be passed in
        opts[:from] = earliest(opts[:url]) unless opts[:from]
        opts.delete(:set) if 'all' == opts[:set]
        begin
          # Connect, and download
          file, records = call(opts.delete(:url), opts)
      
          # Move document to storage directory if configured
          if @directory
            directory_layout = @config.layouts[site] if @config.layouts
            dir = File.join(@directory, date_based_directory(harvest_time, directory_layout))
            FileUtils.mkdir_p dir
            FileUtils.mv(file.path,
              File.join(dir, "#{site}-#{filename(Time.parse(opts[:from]),
              harvest_time)}.xml.gz"))
          else
            puts "no configured destination for temp file" if @interactive
          end
          @config.sites[site]['last'] = harvest_time
        rescue OAI::NoMatchException
          puts "No new records available" if @interactive
        rescue OAI::Exception => ex
          raise ex if not @interactive
          puts ex.message
        end
      end
    
      def call(url, opts)
        # Preserve original options
        options = opts.dup
        
        records = 0;
        client = OAI::Client.new(url, :parser => @parser)
        provider_config = client.identify

        file = Tempfile.new('oai_data')
        gz = Zlib::GzipWriter.new(file)
        gz << "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
        gz << "<records>"
        begin
          response = client.list_records(options)
          response.each do |rec|
            gz << rec._source
            records += 1
          end
          puts "#{records} records retrieved" if @interactive

          # Get a full response by iterating with the resumption tokens.  
          # Not very Ruby like.  Should fix OAI::Client to handle resumption
          # tokens internally.
          while(response.resumption_token and not response.resumption_token.empty?)
            puts "\nresumption token recieved, continuing" if @interactive
            response = client.list_records(:resumption_token => 
              response.resumption_token)
              response.each do |rec|
                gz << rec._source
                records += 1
              end
            puts "#{records} records retrieved" if @interactive
          end

            gz << "</records>"
            
        ensure
          gz.close
          file.close
        end

        [file, records]
      end
    
      def get_records(doc)
        doc.find("/OAI-PMH/ListRecords/record").to_a
      end
    
      def build_options_hash(site)
        options = {:url => site['url']}
        options[:set] = site['set'] if site['set']
        options[:from] = site['last'].utc.xmlschema if site['last']
        options[:metadata_prefix] = site['prefix'] if site['prefix']
        options
      end
    
      def date_based_directory(time, directory_layout = nil)
        directory_layout ||= Harvest::DIRECTORY_LAYOUT
        "#{time.strftime(directory_layout)}"
      end

      def filename(from_time, until_time)
        format = "%Y-%m-%d"
        "#{from_time.strftime(format)}_til_#{until_time.strftime(format)}"\
        "_at_#{until_time.strftime('%H-%M-%S')}"
      end

      def granularity(url)
        client = OAI::Client.new url
        client.identify.granularity
      end

      # Get earliest timestamp from repository
      def earliest(url)
        client = OAI::Client.new url
        identify = client.identify
        if OAI::Const::Granularity::LOW == identify.granularity
          Time.parse(identify.earliest_datestamp).strftime("%Y-%m-%d")
        else
          Time.parse(identify.earliest_datestamp).xmlschema
        end
      end
    
    end
  
  end
end
