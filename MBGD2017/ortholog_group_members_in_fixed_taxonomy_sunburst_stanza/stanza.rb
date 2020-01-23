class OrthologGroupMembersInFixedTaxonomySunburstStanza < TogoStanza::Stanza::Base
  property :title do |cluster_id|
    "Cluster ID #{cluster_id}"
  end

  property :param_cluster_id do |cluster_id|
    cluster_id
  end

  resource :features do |cluster_id|
    existset = query('http://sparql.nibb.ac.jp/sparql', <<-SPARQL.strip_heredoc)
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX taxont: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
        PREFIX orthology: <http://purl.org/net/orth#>
        PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
        PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
        SELECT ?tax COUNT(?tax) AS ?cnt ?tax_label ?parent ?rank
        WHERE {
        ?group a orthology:OrthologsCluster ;
            void:inDataset mbgdr:default ;
            dct:identifier "#{cluster_id}" ;
            orthology:hasHomologous ?member .
        ?member mbgd:organism ?organism .
        ?organism mbgd:inTaxon ?tax .
        ?tax a mbgd:TaxonShown ;
             taxont:scientificName ?tax_label ;
             taxont:rank ?rank .
        OPTIONAL { ?tax mbgd:parentTaxonShown ?parent }.
        }
   SPARQL

    allset = query('http://sparql.nibb.ac.jp/sparql', <<-SPARQL.strip_heredoc)
        PREFIX taxont: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
        PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
        PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
        SELECT distinct ?tax COUNT(?tax) AS ?cnt ?tax_label ?parent ?rank
        WHERE {
            mbgdr:default mbgd:organism ?organism .
            ?organism mbgd:inTaxon ?tax .
            ?tax a mbgd:TaxonShown ;
                 taxont:rank ?rank ;
                 taxont:scientificName ?tax_label .
            OPTIONAL { ?tax mbgd:parentTaxonShown ?parent }.
        }
   SPARQL

   #h = Hash.new { |h,k| h[k] = {} }
   #tmphash = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }

   root = {:tax => "http://identifiers.org/taxonomy/131567", :tax_label => "Cellular_organism", :rank => "SuperKingdom", :cnt => 1}

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
