class OrthologGroupMembersStanza < TogoStanza::Stanza::Base
  property :title do |cluster_id|
    "Cluster ID #{cluster_id}"
  end

  property :cluster_id do |cluster_id|
    cluster_id
  end

  property :dataset do |dataset|
    dataset
  end

  resource :features do |cluster_id, dataset|
    results = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
    #results = query('http://mbgd.genome.ad.jp:3002/sparql', <<-SPARQL.strip_heredoc)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dct: <http://purl.org/dc/terms/>
    PREFIX up: <http://purl.uniprot.org/core/>
    PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
    PREFIX orth: <http://purl.jp/bio/11/orth#>

    SELECT ?superkingdom ?phylum ?organism_name ?domain ?gene_description
    WHERE {
    ?cluster a orth:OrthologGroup ;
            orth:inDataset mbgdr:#{dataset} ;
            dct:identifier "#{cluster_id}";
            orth:member ?member .
    ?member orth:gene ?gene ;
            orth:organism ?organism ;
            rdfs:label ?domain .
    ?organism dct:description ?organism_name ;
            orth:taxon ?tax_id .   
    ?gene dct:description ?gene_description .
    ?tax_id rdfs:subClassOf+ ?taxon .
    ?taxon up:rank up:Superkingdom ;
           up:scientificName ?superkingdom .
    OPTIONAL {
        ?tax_id rdfs:subClassOf+ ?phylum_id .
        ?phylum_id up:rank up:Phylum ;
                   up:scientificName ?phylum .
    }
    }
    ORDER BY ?superkingdom ?phylum ?organism_name ?domain

   SPARQL
   #h = {}
   h = Hash.new { |h,k| h[k] = {} }
   tmphash = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }
   #tmphash[:superkingdom] = 0;
   #tmphash[:phylum] = 0;
   #tmphash[:organism_name] = 0;

   results.each do |foo|
       kingdom = foo[:superkingdom] ? foo[:superkingdom] : 'none'
       phylm = foo[:phylum] ? foo[:phylum] : 'none ('+kingdom+')'
       orgnsm = foo[:organism_name] ? foo[:organism_name] : 'none'
       domain = foo[:domain] ? foo[:domain] : 'none'
       gene = foo[:gene_description] ? foo[:gene_description] : 'none'
       tmphash[kingdom][phylm][orgnsm][domain] = gene
       h[:phylum][phylm] = h[:phylum][phylm] ? h[:phylum][phylm] + 1 : 1
       h[:organism_name][orgnsm] = h[:organism_name][orgnsm] ? h[:organism_name][orgnsm] + 1 : 1
       h[:superkingdom][kingdom] = h[:superkingdom][kingdom] ? h[:superkingdom][kingdom] + 1 : 1
       kingdom = ''
       phylm = ''
       orgnsm = ''
       domain = ''
       gene = ''
   end
   h[:superkingdom].keys.each do |key1|
	tmphash[key1][:count] = h[:superkingdom][key1]
	h[:phylum].keys.each do |key2|
          if(tmphash[key1].has_key?(key2)) then 
	     tmphash[key1][key2][:count] = h[:phylum][key2] 
	     h[:organism_name].keys.each do |key3|
		if(tmphash[key1][key2].has_key?(key3)) then tmphash[key1][key2][key3][:count] = h[:organism_name][key3] end
	     end
	  end
        end
   end

   
   results.unshift(tmphash)
   #grouping(features, :superkingdom, :phylum)
  end
end
