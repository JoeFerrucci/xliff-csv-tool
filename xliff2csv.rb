#!/usr/bin/env ruby

require 'nokogiri'
require 'csv'
require 'byebug'
require 'sanitize'

# ruby xliff2csv.rb -S SourceFolder
if $stdin.tty?
  if ARGV[0] == '--SourceFolder' || ARGV[0] == '-S'
    folder= ARGV[1]
  else
    puts "no source folder was specified after -S or -SourceFolder, need to know where to read from"
    exit 0
  end
end

if folder[-1..-1]=="/"
    folder= folder[0..-2]
end

files = Dir.glob(folder+'/*.xliff')
csv_filename = folder.split("/").last

class Hash
    def to_string
        size = self.size
        count= 0
        self.inject("") do |accu,(k,v)|
            count +=1
            accu  +="#{k.to_s}=#{v}"
            accu  +="&" unless count == size
            accu
        end
    end
end

CSV.open( "#{csv_filename}.csv","w+",{:col_sep => ","}) do |csv|
    csv << ["Filename","File_params","Trans-unit_params","same","Source","sc","Target","Note","tc"]
    files.each do |file|
        f = File.open(file)
        doc = Nokogiri::XML(f,nil,'UTF-8') do |config|
            config.options = Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET
        end

        filename     = file.split("/").last
        params        = {}
        fileNodes             = doc.xpath("//x:file", "x" => "urn:oasis:names:tc:xliff:document:1.2")

        fileNodes.each_with_index do |file_params, index|
            params[:original]       = file_params.attr("original")
            params[:source]         = file_params.attr("source-language")
            params[:target]         = file_params.attr("target-language")
            params[:datatype]       = file_params.attr("datatype")

            trans_units_params      = file_params.search("trans-unit") #, "x" => "urn:oasis:names:tc:xliff:document:1.2")
            trans_units_params.each_with_index do |trans_params, index|
                trans_unit = {}
                trans_unit[:id]        = trans_params.attr('id')

                sourceNode = trans_params.search("source") # , "x" => "urn:oasis:names:tc:xliff:document:1.2")
                source = ""
                if sourceNode != nil
                    source = sourceNode.text
                end

                targetNode = trans_params.search("target") #, "x" => "urn:oasis:names:tc:xliff:document:1.2")
                target = ""
                if targetNode != nil
                    target = targetNode.text
                end    
                
                noteNode = trans_params.search("note") #, "x" => "urn:oasis:names:tc:xliff:document:1.2")
                note = ""
                if noteNode != nil
                    note = noteNode.text
                end

                same = ((source == target) ? 1 :0)

                csv << [filename,params.to_string,trans_unit.to_string,same,source,Sanitize.clean(source).split.size,target,note,Sanitize.clean(target).split.size]
            end
        end
        f.close
    end
end