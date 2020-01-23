class TaxidToGeneFunctionsStanza < TogoStanza::Stanza::Base
  property :param_tax_id do |tax_id|
    tax_id
  end

  property :adjust_iframe_height_script do
    "260"
  end

  property :features do |tax_id|
  features = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX orth: <http://purl.jp/bio/11/orth#>
PREFIX mgfo: <http://purl.jp/bio/11/mgfo#>
PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
PREFIX tax: <http://purl.uniprot.org/taxonomy/>

SELECT ?function ?color ?label COUNT(?function) AS ?count
WHERE {
    ?cluster a orth:OrthologGroup ;
          orth:inDataset mbgdr:default ;
          orth:member/orth:gene/orth:organism/orth:taxon tax:#{tax_id} ;
    	  mgfo:funcMBGD ?mbgd_func .
    ?mbgd_func
          rdfs:label ?label ;
          dct:identifier ?function ;
          mgfo:colorCode ?color .
}
ORDER BY ?function
    SPARQL
features.map {|result|
  cc = result[:count]
result.replace(:function => result[:function], :label => result[:label], :color => result[:color], :counts => cc)
}
  end
end
