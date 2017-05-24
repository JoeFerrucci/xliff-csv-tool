#!/usr/bin/env ruby

require 'nokogiri'
require 'csv'
require 'byebug'
require 'fileutils'

def query2hash(string)
    return {} if string.nil?
    string.split('&').inject({}) do |hash,keyval|
        tmp =keyval.split('=')
        hash[tmp[0]]=tmp[1]
        hash
    end
end

# ruby csv2xliff.rb translated_xliff.csv -T TargetFolder
if $stdin.tty?
  csv_filename= ARGV[0]
  unless csv_filename[-4..-1] == ".csv"
    puts "missing first parameter, need to know which csv file"
    exit 0
end
if ARGV[1] == '--TargetFolder' || ARGV[1] == '-T'
    folder= ARGV[2]
else
    puts "no target folder was specified after -T or -TargetFolder, need to know where to save to"
    exit 0
end
end

if folder[-1..-1]=="/"
    folder= folder[0..-2]
end

FileUtils.mkdir_p(folder)
#Read csv with header: Filename   File_params   Trans-unit_params   same   Source   sc  Target  Note  tc
filescollection = Hash.new(Array.new)

filename = ""
CSV.foreach( csv_filename ,{:headers => :string,:col_sep => ",",:encoding => "bom|utf-8"}) do |row|
    filename = row["Filename"]
    file_params=query2hash(row["File_params"])
    tu_params=query2hash(row["Trans-unit_params"])
    filescollection[file_params["original"]] += [ [file_params,tu_params,row["Source"],row["Target"],row["Note"]] ]
end


builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
    xml.xliff(:version => "1.2",:xmlns => "urn:oasis:names:tc:xliff:document:1.2") {
        filescollection.each do |file,content|
            file_params= content.first.first
            xml.file(:original => file_params['original'],:"source-language" => file_params['source'],:"target-language" => file_params['target'],:datatype => file_params['datatype']) {
                xml.body {
                    content.each do |data|
                        tu= data[1]
                        xml.send(:"trans-unit",:id => tu['id']) {
                            xml.source data[2]

                            if data[3] != nil 
                                xml.target data[3]
                            else
                                xml.target data[2]
                            end 

                            if data[4] == nil
                                xml.note "No comment provided by engineer"
                            else
                                xml.note data[4]
                            end
                        }
                    end
                }
            }
        end
    }
}

#save the file with builder.to_xml
File.open(folder + "/" + filename,'w+') do |f|
    f.puts builder.to_xml
end