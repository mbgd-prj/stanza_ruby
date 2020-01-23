class OrthologGroupMembersInFixedTaxonomySunburstStanza < TogoStanza::Stanza::Base
  property :title do |cluster_id|
    "Cluster ID #{cluster_id}"
  end

  property :param_cluster_id do |cluster_id|
    cluster_id
  end

  resource :features do |cluster_id|
    #existset = query('http://mbgd.genome.ad.jp:3002/sparql', <<-SPARQL.strip_heredoc)
    existset = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX orth: <http://purl.jp/bio/11/orth#>
        PREFIX up: <http://purl.uniprot.org/core/>
        PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
        SELECT ?tax COUNT(?tax) AS ?cnt ?tax_label ?parent ?rank
        WHERE {
                <http://mbgd.genome.ad.jp/rdf/resource/default/cluster/#{cluster_id}>
         orth:member ?member.
        ?member orth:organism/orth:taxon ?org_tax .
        ?org_tax rdfs:subClassOf* ?tax .
        ?tax up:scientificName ?tax_label .
        ?tax a mbgd:TaxonShown .
        ?tax up:rank ?rank .
        OPTIONAL { ?tax rdfs:subClassOf ?parent }.
        }
   SPARQL

    #allset = query('http://mbgd.genome.ad.jp:3002/sparql', <<-SPARQL.strip_heredoc)
    allset = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX orth: <http://purl.jp/bio/11/orth#>
        PREFIX up: <http://purl.uniprot.org/core/>
        PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
        SELECT distinct ?tax COUNT(?tax) AS ?cnt ?tax_label ?parent ?rank
        WHERE {
         ?org_tax a mbgd:TaxonShown .
         ?org_tax rdfs:subClassOf* ?tax .
         ?tax up:scientificName ?tax_label .
         ?tax up:rank ?rank .
         OPTIONAL { ?tax rdfs:subClassOf ?parent }.
        }
   SPARQL

   #h = Hash.new { |h,k| h[k] = {} }
   #tmphash = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }

   root = {:tax => "http://purl.uniprot.org/taxonomy/131567", :tax_label => "Cellular_organism", :rank => "SuperKingdom", :cnt => 1}

   allset.each do |foo|
       foo[:cnt] = 0
       tmplab = foo[:tax_label].gsub(/\s/, '_')
       foo[:tax_label] = tmplab 
       existset.each do |eoo|
          if eoo[:tax] == foo[:tax] then
	     foo[:cnt] = eoo[:cnt]
          end
       end
   end
   allset.push(root)
end
end
