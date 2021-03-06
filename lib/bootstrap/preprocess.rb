module FHIR
  module Boot
    class Preprocess

      def self.pre_process_bundle(filename)
        # Read the file
        puts "Processing #{File.basename(filename)}..."
        start = File.size(filename)
        json = File.open(filename,'r:UTF-8',&:read)
        hash = JSON.parse(json)

        # Remove entries that do not interest us: CompartmentDefinitions, OperationDefinitions, Conformance statements
        hash['entry'].select! do |entry|
          ['StructureDefinition','ValueSet','CodeSystem'].include? entry['resource']['resourceType']
        end

        # Remove unnecessary elements from the hash
        hash['entry'].each do |entry|
          if entry['resource']
            pre_process_structuredefinition(entry['resource']) if 'StructureDefinition'==entry['resource']['resourceType']
            pre_process_valueset(entry['resource']) if 'ValueSet'==entry['resource']['resourceType']
            pre_process_codesystem(entry['resource']) if 'CodeSystem'==entry['resource']['resourceType']
            remove_fhir_comments(entry['resource'])
          end
        end

        # Output the post processed file
        f = File.open(filename,'w:UTF-8')
        f.write(JSON.pretty_unparse(hash))
        f.close
        finish = File.size(filename)
        puts "  Removed #{(start-finish) / 1024} KB" if (start!=finish)
      end

      def self.pre_process_structuredefinition(hash)
        # Remove large HTML narratives and unused content
        ['text','publisher','contact','description','requirements','mapping'].each{|key| hash.delete(key) }
        
        # Remove unused descriptions within the snapshot elements
        if(hash['snapshot'])
          hash['snapshot']['element'].each do |element|
            ['short','definition','comments','requirements','alias','mapping'].each{|key| element.delete(key) }
          end
        end
        # Remove unused descriptions within the differential elements
        if(hash['differential'])
          hash['differential']['element'].each do |element|
            ['short','definition','comments','requirements','alias','mapping'].each{|key| element.delete(key) }
          end
        end
      end

      def self.pre_process_valueset(hash)
        # Remove large HTML narratives and unused content
        ['meta','text','publisher','contact','description','requirements'].each{|key| hash.delete(key) }

        if(hash['compose'] && hash['compose']['include'])
          hash['compose']['include'].each do |element|
            if(element['concept'])
              element['concept'].each do |concept|
                concept.delete('designation')
              end 
            end
          end
        end

        if(hash['compose'] && hash['compose']['exclude'])
          hash['compose']['exclude'].each do |element|
            if(element['concept'])
              element['concept'].each do |concept|
                concept.delete('designation')
              end 
            end
          end
        end
      end

      def self.pre_process_codesystem(hash)
        # Remove large HTML narratives and unused content
        ['meta','text','publisher','contact','description','requirements'].each{|key| hash.delete(key) }

        if(hash['concept'])
          hash['concept'].each do |concept|
            pre_process_codesystem_concept(concept)
          end
        end
      end

      def self.pre_process_codesystem_concept(hash)
        ['extension','definition','designation'].each{|key| hash.delete(key) }
        if hash['concept']
          hash['concept'].each do |concept|
            pre_process_codesystem_concept(concept)
          end
        end
      end

      def self.remove_fhir_comments(hash)
        hash.delete('fhir_comments')
        hash.each do |key,value|
          if value.is_a?(Hash)
            remove_fhir_comments(value)
          elsif value.is_a?(Array)
            value.each do |v|
              remove_fhir_comments(v) if v.is_a?(Hash)
            end
          end
        end
        hash.keep_if do |key,value|
          !value.is_a?(Hash) || !value.empty?
        end
      end

      def self.pre_process_schema(filename)
        # Read the file
        puts "Processing #{File.basename(filename)}..."
        start = File.size(filename)
        raw = File.open(filename,'r:UTF-8',&:read)

        # Remove annotations
        doc = Nokogiri::XML(raw)
        doc.root.add_namespace_definition('xs', 'http://www.w3.org/2001/XMLSchema')
        doc.search('//xs:annotation').each{ |e| e.remove }

        # Output the post processed file
        f = File.open(filename,'w:UTF-8')
        f.write(doc.to_xml)
        f.close
        finish = File.size(filename)
        puts "  Removed #{(start-finish) / 1024} KB" if (start!=finish)
      end

    end
  end
end