class TaxonToSpecificGenesInDatasetStanza < TogoStanza::Stanza::Base
  property :title do |tax_id|
    "Cluster ID #{tax_id}"
  end

  property :param_tax_id do |tax_id|
    tax_id
  end

  property :param_ortholog_dataset do |ortholog_dataset|
    ortholog_dataset
  end

  property :features do |tax_id, ortholog_dataset|
    features = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIX tax: <http://purl.uniprot.org/taxonomy/>
      PREFIX orth: <http://purl.jp/bio/11/orth#>
      PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>

      SELECT ?group ?label ?description ?ratio ?ratio2 ?count_organism_all ?count_organism_all2
      WHERE {
       {
        SELECT ?group ?label ?description ?ratio ?ratio2 ?count_organism_all ?count_organism_all2
        WHERE {
            ?group a orth:OrthologGroup ;
                   orth:inDataset mbgdr:#{ortholog_dataset} ;
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
                    mbgdr:#{ortholog_dataset} orth:organism ?organism_all .
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
                    mbgdr:#{ortholog_dataset} orth:organism ?organism_all2 .
                    MINUS {
                        ?organism_all2 mbgd:inTaxon tax:#{tax_id} .
                    }
                }
            }
            BIND (IF(BOUND(?count_tmp), ?count_tmp, 0) AS ?count)
            BIND (IF(BOUND(?count_tmp2), ?count_tmp2, 0) AS ?count2)
            BIND ((xsd:decimal(?count)/?count_organism_all) AS ?ratio)
            BIND ((xsd:decimal(?count2)/?count_organism_all2) AS ?ratio2)
          }
      }
      FILTER (?ratio >= 0.8)
      FILTER (?ratio2 <= 0.2)
      }
      ORDER BY ?ratio2 DESC(?ratio)
   SPARQL
    features.map {|genes|
      gene_uri = genes[:group]
      genes.replace(:group => gene_uri.split('/').last, :label => genes[:label], :description => genes[:description], :ratio => genes[:ratio].to_f.round(2), :ratio2 => genes[:ratio2].to_f.round(2), :count_organism_all => genes[:count_organism_all], :count_organism_all2 => genes[:count_organism_all2])
    }
  end
end
