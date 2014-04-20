=begin
/**
 *  The MIT License (MIT)
 *
 *  Copyright (c) 2014 Jeremy Hahn
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 *
 *  Load, parses, and returns a native ruby OO interface for the specified INI file.
 */
=end

require 'ostruct'

class SectionOpenStruct < OpenStruct

  def initialize(section) 
    @section = section
  end

  def method_missing(m, *args, &block)
    return @section.has_key?(args[0].to_s) ? @section[args[0].to_s][:value] : nil
  end

end

class RubyINI

    def initialize(sections)

        sections.each do |section|

          section_name = nil
          section_hash = nil
          section_struct = nil

          section.each do |key, property|

            if key == "__section_name__"
               section_name = property
               section_hash = Hash.new 
               section_struct = SectionOpenStruct.new(section)
            else
                section_hash[property[:name].to_sym] = property[:value]
            end
          end

          section_struct.marshal_load(section_hash)

          self.class.send(:define_method, section_name, proc {
            return section_struct
          })

          self.class.send(:define_method, "method_missing", proc { |*args|
            return nil
          })

        end
    end

    def method_missing(*args, &block)
        return nil
    end
end

def load_config(file_path, overrides=[])

  current_section = Hash.new;
  sections = []

  File.open(file_path).readlines.each do |line|

      section_name = line[/\[(.*)\]/, 1]

      if section_name != nil

          next if current_section.has_key?("__section_name__") && current_section["__section_name__"] == section_name
          next if current_section.has_key?("__section_name__") && section_name == nil

          sections.push(current_section) if current_section.length > 0
          current_section = Hash.new
          current_section["__section_name__"] = section_name
      else

          line.strip!
          next if line.empty? || line == nil || line.chars.first == ";"
  
          # split "name=value" key pair
          arr = line.split("=")
          next if arr.size != 2
  
          arr[0].strip!
          arr[1].strip!
  
          # store property substrings per requirements
          property = {
            :name => "",
            :override => "",
            :value => ""
          }
  
          # parse name/override from key part
          pointer = :name
          arr[0].each_char do |char|
            case char
                when "<"
                     pointer = :override
                     next
                when ">"
                     break
                else
                     property[pointer] += char    
            end
          end

          # parse data types from value part
          buffer = ""
          array_value = []
          has_quote = false
          arr[1].each_char do |char|
              case char
                when ";"
                     break
                when "\"" || "'"
                     has_quote = true
                     next
                when ","
                  if has_quote
                    buffer += char
                    next
                  end
                  array_value.push buffer
                  buffer = ""
                  next
                else
                     buffer += char
              end
          end
  
          # set parsed value
          if array_value.size > 0
             array_value.push(buffer) if buffer.size > 0
             property[:value] = array_value;
          elsif buffer.downcase == "yes" || buffer == "1"
              property[:value] = "true"
          elsif buffer.downcase == "no" || buffer == "0"
              property[:value] = "false"
          else
             property[:value] = buffer
          end
  
          # apply overrides
          if current_section.has_key?(property[:name])
              if overrides.include?(property[:override]) || overrides.include?(property[:override].to_sym) 
                 current_section.update(property[:name] => property);
              end
          else
              current_section[property[:name]] = property
          end
      end
  end

  # push the final, left-over section onto the stack
  sections.push(current_section) if current_section.length > 0

  return RubyINI.new(sections)
end
