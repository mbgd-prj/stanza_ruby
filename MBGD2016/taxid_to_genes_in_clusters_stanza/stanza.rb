class TaxidToGenesInClustersStanza < TogoStanza::Stanza::Base
  property :title do |tax_id|
    "Organism code #{tax_id}"
  end

  property :tax_id do |tax_id|
    tax_id
  end

  resource :features do |tax_id|
  results = query('http://mbgd.genome.ad.jp:7050/sparql', <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
      PREFIX mgfo: <http://purl.jp/bio/11/mgfo#>
      PREFIX orth: <http://purl.jp/bio/11/orth#>
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX tax: <http://purl.uniprot.org/taxonomy/>
      PREFIX org: <http://mbgd.genome.ad.jp/rdf/resource/organism/>
      SELECT DISTINCT ?gene ?gene_id ?gene_name ?domain_no ?cluster ?cluster_id ?color ?cluster_descr
	WHERE {
    	?cluster a orth:OrthologGroup ;
          orth:inDataset mbgdr:default ;
          dct:identifier ?cluster_id ;
          mgfo:funcMBGD/mgfo:colorCode ?color ;
          dct:description ?cluster_descr ;
          orth:member ?domain .
    	?domain dct:identifier ?domain_no ;
          orth:gene ?gene .
          ?gene orth:organism/orth:taxon tax:#{tax_id} ;
          rdfs:label ?gene_name ;
          dct:identifier ?gene_id .
}
   ORDER BY ?gene_id

    SPARQL
  end
end
