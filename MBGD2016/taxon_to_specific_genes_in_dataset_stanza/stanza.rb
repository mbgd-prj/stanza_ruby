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
    features = query('http://mbgd.genome.ad.jp:7050/sparql', <<-SPARQL.strip_heredoc)
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX void: <http://rdfs.org/ns/void#>
PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX taxid: <http://identifiers.org/taxonomy/>
PREFIX orth: <http://purl.jp/bio/11/orth#>
PREFIX oo: <http://purl.org/net/orth#>
PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>

SELECT ?group ?label ?description ?member_count ?ratio ?ratio2 ?count1 ?count2 ?count_organism_all ?count_organism_all2
WHERE {
    {
        SELECT ?group ?label ?description ?member_count ?ratio ?ratio2 ?count1 ?count2 ?count_organism_all ?count_organism_all2
        WHERE {
            ?group a oo:OrthologsCluster ;
                   void:inDataset mbgdr:#{ortholog_dataset} ;
                   rdfs:label ?label ;
                   mbgd:memberCount ?member_count ;
                   dct:description ?description .
            OPTIONAL
            {
                SELECT ?group (COUNT(DISTINCT ?organism) AS ?count_tmp)
                WHERE {
                    ?group oo:hasHomologous ?member .
                    ?member mbgd:organism ?organism .
                    ?organism mbgd:inTaxon taxid:#{tax_id} .
                }
            }
            {
                SELECT (COUNT(?organism_all) AS ?count_organism_all)
                WHERE {
                    mbgdr:#{ortholog_dataset} mbgd:organism ?organism_all .
                    ?organism_all mbgd:inTaxon taxid:#{tax_id} .
                }
            }
            OPTIONAL
            {
                SELECT ?group (COUNT(DISTINCT ?organism2) AS ?count_tmp2)
                WHERE {
                    ?group oo:hasHomologous ?member .
                    ?member mbgd:organism ?organism2 .
                    MINUS {
                        ?organism2 mbgd:inTaxon taxid:#{tax_id} .
                    }
                }
            }
            {
                SELECT (COUNT(?organism_all2) AS ?count_organism_all2)
                WHERE {
                    mbgdr:#{ortholog_dataset} mbgd:organism ?organism_all2 .
                    MINUS {
                        ?organism_all2 mbgd:inTaxon taxid:#{tax_id} .
                    }
                }
            }
            BIND (IF(BOUND(?count_tmp), ?count_tmp, 0) AS ?count1)
            BIND (IF(BOUND(?count_tmp2), ?count_tmp2, 0) AS ?count2)
            BIND ((xsd:decimal(?count1)/?count_organism_all) AS ?ratio)
            BIND ((xsd:decimal(?count2)/?count_organism_all2) AS ?ratio2)
        }
    }
    FILTER (?ratio >= 0.8)
    FILTER (?ratio2 <= 0.2)
}
ORDER BY ?ratio2 DESC(?ratio) DESC(?member_count)
SPARQL
    features.map {|genes|
      gene_uri = genes[:group]
      genes.replace(:group => gene_uri.split('/').last, :label => genes[:label], :description => genes[:description], :ratio => genes[:ratio].to_f.round(2), :ratio2 => genes[:ratio2].to_f.round(2), :count_organism_all => genes[:count_organism_all], :count_organism_all2 => genes[:count_organism_all2], :count1 => genes[:count1], :count2 => genes[:count2], :member_count => genes[:member_count])
    }
  end
end
