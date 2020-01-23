class OrthologGroupMembersInFixedTaxonomyTreeStanza < TogoStanza::Stanza::Base
  property :param_cluster_id do |cluster_id|
   cluster_id
  end
  property :param_dataset do |dataset|
   dataset
  end

  resource :features do |cluster_id, dataset|
  org = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
        PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
        PREFIX orth: <http://purl.jp/bio/11/orth#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
        SELECT ?taxon (COUNT(?organism) AS ?organism_count)
         WHERE {
           SELECT DISTINCT ?taxon ?organism
            WHERE {
            ?group a orth:OrthologGroup ;
            orth:inDataset mbgdr:#{dataset} ;
            dct:identifier "#{cluster_id}";
            orth:member/orth:organism ?organism .
        ?organism orth:taxon ?taxid .
        ?taxid rdfs:subClassOf* ?taxon .
        ?taxon a mbgd:TaxonShown .
    }
   }
   SPARQL

  member = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
      PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX orth: <http://purl.jp/bio/11/orth#>
      SELECT ?taxon (COUNT(?member) AS ?member_count)
       WHERE {
        SELECT DISTINCT ?taxon ?member
        WHERE {
        ?group a orth:OrthologGroup ;
            orth:inDataset mbgdr:#{dataset} ;
            dct:identifier "#{cluster_id}";
            orth:member ?member .
        ?member orth:organism ?organism .
        ?organism orth:taxon ?taxid .
        ?taxid rdfs:subClassOf* ?taxon .
        ?taxon a mbgd:TaxonShown .
      }
     }
    SPARQL
    
   all = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
        PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX orth: <http://purl.jp/bio/11/orth#>
        PREFIX up: <http://purl.uniprot.org/core/>
        PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
        SELECT distinct ?tax COUNT(?organism) as ?cnt ?tax_label ?parent ?rank
        WHERE {
         mbgdr:#{dataset} orth:organism ?organism .
         ?organism orth:taxon ?taxid .
         ?taxid rdfs:subClassOf* ?tax .
         ?tax a mbgd:TaxonShown .
         ?tax up:scientificName ?tax_label .
         ?tax up:rank ?rank .
         OPTIONAL { ?tax rdfs:subClassOf ?parent }.
        }
    SPARQL
    
    all.each do |all_foo|
      all_foo[:ocnt] = 0
      all_foo[:mcnt] = 0
      all_foo[:para] = 0
      all_foo[:ratio] = 0
      all_foo[:cnt] = all_foo[:cnt].to_f
      label = all_foo[:tax_label].gsub(/\s/, "_")
      all_foo[:tax_label] = label
      org.each do |org_foo|
	  if (all_foo[:tax] == org_foo[:taxon]) then 
	    all_foo[:ocnt] = org_foo[:organism_count].to_f
	    next
          end
      end
      member.each do |mem_foo|
	  if (all_foo[:tax] == mem_foo[:taxon]) then
	    all_foo[:mcnt] = mem_foo[:member_count].to_f
	    all_foo[:ratio] = all_foo[:ocnt] / all_foo[:cnt]
	    all_foo[:para] = all_foo[:mcnt] / all_foo[:ocnt]
	    next
          end
      end
    end
root = {:tax => "http://purl.uniprot.org/taxonomy/131567", :cnt => 1, :tax_label => "Cellular_organism", :ratio => 1, :rank => "http://purl.uniprot.org/core/SuperKingdom", :parent => "root", :link => "http://mbgd.genome.ad.jp"}
   all.push(root)
    
    end
end
