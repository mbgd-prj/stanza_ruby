class OrganismToGeneFunctionsStanza < TogoStanza::Stanza::Base
  property :param_org_code do |org_code|
    org_code
  end

  property :adjust_iframe_height_script do
    "260"
  end

  property :features do |org_code|
  features = query('http://mbgd.genome.ad.jp:7050/sparql', <<-SPARQL.strip_heredoc)
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX orth: <http://purl.jp/bio/11/orth#>
PREFIX mgfo: <http://purl.jp/bio/11/mgfo#>
PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
PREFIX org: <http://mbgd.genome.ad.jp/rdf/resource/organism/>

SELECT ?function ?color ?label COUNT(?function) AS ?count
WHERE {
    ?cluster a orth:OrthologGroup ;
          orth:inDataset mbgdr:default ;
          orth:member/orth:gene/orth:organism org:#{org_code} ;
    	  mgfo:funcMBGD ?mbgd_func .
    ?mbgd_func
          rdfs:label ?label ;
          mgfo:funcCode ?function ;
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
