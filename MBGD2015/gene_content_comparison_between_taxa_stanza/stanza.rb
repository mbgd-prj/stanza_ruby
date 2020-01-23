class GeneContentComparisonBetweenTaxaStanza < TogoStanza::Stanza::Base
  property :params do |tax_id, dataset, ratio1, ratio2|
    if ratio1.nil? || ratio1 == ''
      ratio1 = '0.8'
    end
    if ratio2.nil? || ratio2 == ''
      ratio2 = '0.2'
    end
    if dataset.nil? || dataset == ''
      dataset = 'extended'
    end
    #TODO validate parameters tax_id count = 2, ratio range etc..
    {tax_id: tax_id, dataset: dataset, ratio1: ratio1, ratio2: ratio2 }
  end

  property :features do |tax_id, dataset, ratio1, ratio2|
    tax = "#{tax_id}"
    taxAry = tax.split(",")
    
    #features = query('http://mbgd.genome.ad.jp:3002/sparql', <<-SPARQL.strip_heredoc)
     features = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
	PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
	PREFIX tax: <http://purl.uniprot.org/taxonomy/>
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX orth: <http://purl.jp/bio/11/orth#>
	PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
	PREFIX dct: <http://purl.org/dc/terms/>
	PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>

	SELECT ?group ?label ?description ?ratio ?ratio2
	WHERE {
    	{
        SELECT ?group ?label ?description ?ratio ?ratio2
        WHERE {
            ?group a orth:OrthologGroup ;
                   orth:inDataset mbgdr:#{dataset} ;
                   rdfs:label ?label ;
                   dct:description ?description .
            OPTIONAL
            {
                SELECT ?group (COUNT(DISTINCT ?organism) AS ?count_tmp)
                WHERE {
                    ?group orth:member ?member .
                    ?member orth:organism ?organism .
                    ?organism mbgd:inTaxon tax:#{taxAry[0]} .
                }
            }
            {
                SELECT (COUNT(?organism_all) AS ?count_organism_all)
                WHERE {
                    mbgdr:#{dataset} orth:organism ?organism_all .
                    ?organism_all mbgd:inTaxon tax:#{taxAry[0]} .
                }
            }
            OPTIONAL
            {
                SELECT ?group (COUNT(DISTINCT ?organism2) AS ?count_tmp2)
                WHERE {
                    ?group orth:member ?member .
                    ?member orth:organism ?organism2 .
                    ?organism2 mbgd:inTaxon tax:#{taxAry[1]} .
                }
            }
            {
                SELECT (COUNT(?organism_all2) AS ?count_organism_all2)
                WHERE {
                    mbgdr:#{dataset} orth:organism ?organism_all2 .
                    ?organism_all2 mbgd:inTaxon tax:#{taxAry[1]} .
                }
            }
            BIND (IF(BOUND(?count_tmp), ?count_tmp, 0) AS ?count)
            BIND (IF(BOUND(?count_tmp2), ?count_tmp2, 0) AS ?count2)
            BIND ((xsd:decimal(?count)/?count_organism_all) AS ?ratio)
            BIND ((xsd:decimal(?count2)/?count_organism_all2) AS ?ratio2)
        }
    }
    FILTER (?ratio >= #{ratio1})
    FILTER (?ratio2 <= #{ratio2})
}
ORDER BY ?ratio2 DESC(?ratio) ?label 
   SPARQL
    features.map {|genes|
      gene_uri = genes[:group]
      genes.replace(:group => gene_uri.split('/').last, :label => genes[:label], :description => genes[:description], :ratio => genes[:ratio].to_f.round(2), :ratio2 => genes[:ratio2].to_f.round(2))
    }
  end
end
