class GeneContentComparisonBetweenTaxaWithPositionsStanza < TogoStanza::Stanza::Base
property :title do |tax_id|
  end

  property :param_tax_id do |tax_id|
    tax_id
  end

  property :param_dataset do |dataset|
    dataset
  end

 # property :param_ratio1 do |ratio1|
 #   ratio1
 # end

 # property :param_ratio2 do |ratio2|
 #   ratio2
 # end

  #property :features do |tax_id, dataset, ratio1, ratio2|
  property :features do |tax_id, dataset|
    tax = "#{tax_id}"
    taxAry = tax.split(",")
    
  features = query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX tax: <http://purl.uniprot.org/taxonomy/>
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
      PREFIX faldo: <http://biohackathon.org/resource/faldo#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX orth: <http://purl.jp/bio/11/orth#>
      PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
      PREFIX mgfo: <http://purl.jp/bio/11/mgfo#>
      SELECT DISTINCT ?ref_gene_id ?begin ?chrom_label ?func_cat ?func_label ?description
      WHERE {
       ?ref_gene dct:identifier ?ref_gene_id ;
          dct:description ?description ;
          mbgd:nucSeq/rdfs:label ?chrom_label ;
          faldo:location/faldo:begin/faldo:position ?begin. 
       ?group mgfo:funcMBGD ?exact_func .
       ?exact_func rdfs:subClassOf? ?func .
       ?func dct:identifier ?func_cat ;
          rdfs:label ?func_label ;
          rdfs:subClassOf mgfo:FuncMBGD .
       {
        SELECT ?group ?ratio ?ratio2 ?ref_gene
        WHERE {
            ?group a orth:OrthologGroup ;
                   orth:inDataset mbgdr:#{dataset} ;
                   orth:member/orth:gene ?ref_gene .
            ?ref_gene orth:organism/^mbgd:defaultOrganism tax:#{taxAry[0]} .
            OPTIONAL
            {
                SELECT ?group (COUNT(DISTINCT ?organism) AS ?count)
                WHERE {
                    ?group orth:member/orth:organism ?organism .
                    ?organism mbgd:inTaxon tax:#{taxAry[0]} .
                }
            }
            {
                SELECT (COUNT(?organism_all) AS ?count_organism_all)
                WHERE {
                    ?organism_all mbgd:inTaxon tax:#{taxAry[0]} ;
                                 ^orth:organism mbgdr:#{dataset} .
                }
            }
            OPTIONAL
            {
                SELECT ?group (COUNT(DISTINCT ?organism2) AS ?count2)
                WHERE {
                    ?group orth:member/orth:organism ?organism2 .
                    ?organism2 mbgd:inTaxon tax:#{taxAry[1]} .
                }
            }
            {
                SELECT (COUNT(?organism_all2) AS ?count_organism_all2)
                WHERE {
                    ?organism_all2 mbgd:inTaxon tax:#{taxAry[1]} ;
                                  ^orth:organism mbgdr:#{dataset} .
                }
            }
            BIND (IF(BOUND(?count), ?count, 0) AS ?count_or_0)
            BIND (IF(BOUND(?count2), ?count2, 0) AS ?count2_or_0)
            BIND ((xsd:decimal(?count_or_0)/?count_organism_all) AS ?ratio)
            BIND ((xsd:decimal(?count2_or_0)/?count_organism_all2) AS ?ratio2)
        }
        ORDER BY ?ratio2 DESC(?ratio)
    }
    FILTER (?ratio >= 0.8)
    FILTER (?ratio2 <= 0.2)
}
ORDER BY ?func_cat

   SPARQL
    features.delete_if {|item| 
      item[:chrom_label] =~ /[Pp]lasmid/ }
    func_col = ["#bf7fbf", "#ff7f7f", "#bfffbf", "#bf7fff", "#bfbfff", "#bfff7f", "#ffbfff",
                "#ff7fff", "#ffbf7f", "#ffbfbf", "#ff7fbf", "#bfbf7f", "#bfbfbf", "#ffff7f", "#ffffbf"]
    features.map {|genes|
      genes.replace(:func_cat => genes[:func_cat].split('MBGD').last, :begin => genes[:begin], :func_label => genes[:func_label], :description => genes[:description], :ref_gene_id => genes[:ref_gene_id])
    }
    features.each{|item|
	item[:color] = func_col[item[:func_cat].split('MBGD').last.to_i - 1]
    }
    features = features.sort_by do |line|
        [ line[:func_cat].to_i, line[:description] ]
    end
  end
end
