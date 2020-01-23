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
    results = query('http://sparql.nibb.ac.jp/sparql', <<-SPARQL.strip_heredoc)
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
PREFIX void: <http://rdfs.org/ns/void#>
PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
PREFIX orthology: <http://purl.org/net/orth#>
PREFIX dct: <http://purl.org/dc/terms/>
 SELECT DISTINCT ?superkingdom ?domain ?gene_description ?phylum ?organism_name
 WHERE {
   ?cluster a orthology:OrthologsCluster ;
     void:inDataset mbgdr:#{dataset} ;
     dct:identifier "#{cluster_id}";
     orthology:hasHomologous+ ?gene .
   ?gene a orthology:Gene ;
     dct:identifier ?domain;
     dct:description ?gene_description;
     mbgd:organism ?org .
   ?org rdfs:label ?organism_name ;
     mbgd:inSuperkingdom/rdfs:label ?superkingdom .
   OPTIONAL {
     ?org mbgd:inPhylum/rdfs:label ?phylum .
   }
    OPTIONAL {
        ?child orthology:hasHomologous ?gene .
        ?child mbgd:domain ?cl
 }}
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
