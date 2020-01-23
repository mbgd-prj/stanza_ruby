class TaxonToSpecificGenesStanza < TogoStanza::Stanza::Base
  property :param_tax_id do |tax_id|
    tax_id
  end

  property :adjust_iframe_height_script do
    "260"
  end

  property :features do |tax_id|
  #features = query('http://mbgd.genome.ad.jp:3002/sparql', <<-SPARQL.strip_heredoc)
  features = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
DEFINE sql:select-option "order"
PREFIX orth: <http://purl.jp/bio/11/orth#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
PREFIX tax: <http://purl.uniprot.org/taxonomy/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX up: <http://purl.uniprot.org/core/>

SELECT ?group ?label ?description ?ratio ?ratio2 ?sname
WHERE {
    tax:#{tax_id} up:scientificName ?sname .
    {
        SELECT ?group ?label ?description ?ratio ?ratio2 ?count_organism_all ?count_organism_all2
        WHERE {
            ?group a orth:OrthologGroup ;
                   orth:inDataset mbgdr:default ;
                   rdfs:label ?label ;
                   dct:description ?description .
            OPTIONAL
            {
                SELECT ?group (COUNT(DISTINCT ?organism) AS ?count_tmp)
                WHERE {
                    ?group orth:member ?member .
                    ?member orth:organism ?organism .
                    ?organism mbgd:inTaxon tax:#{tax_id} .
                }
            }
            {
                SELECT (COUNT(?organism_all) AS ?count_organism_all)
                WHERE {
                    mbgdr:default orth:organism ?organism_all .
                    ?organism_all mbgd:inTaxon tax:#{tax_id} .
                }
            }
            OPTIONAL
            {
                SELECT ?group (COUNT(DISTINCT ?organism2) AS ?count_tmp2)
                WHERE {
                    ?group orth:member ?member .
                    ?member orth:organism ?organism2 .
                    MINUS {
                        ?organism2 mbgd:inTaxon tax:#{tax_id} .
                    }
                }
            }
            {
                SELECT (COUNT(?organism_all2) AS ?count_organism_all2)
                WHERE {
                    mbgdr:default orth:organism ?organism_all2 .
                    MINUS {
                        ?organism_all2 mbgd:inTaxon tax:#{tax_id} .
                    }
                }
            }
            BIND (IF(BOUND(?count_tmp), ?count_tmp, 0) AS ?count)
            BIND (IF(BOUND(?count_tmp2), ?count_tmp2, 0) AS ?count2)
            BIND (IF(?count_organism_all!=0, xsd:decimal(?count)/?count_organism_all, 0) AS ?ratio)
            BIND (IF(?count_organism_all2!=0, xsd:decimal(?count2)/?count_organism_all2, 0) AS ?ratio2)
        }
    }
    FILTER (?ratio >= 0.8)
    FILTER (?ratio2 <= 0.2)
}
ORDER BY ?ratio2 DESC(?ratio)
    SPARQL

    features.map {|genes|
      gene_uri = genes[:group]
      genes.replace(:group => gene_uri.split('/').last, :sname => genes[:sname], :label => genes[:label], :description => genes[:description], :ratio => genes[:ratio].to_f.round(2), :ratio2 => genes[:ratio2].to_f.round(2))
    }
  end
end
