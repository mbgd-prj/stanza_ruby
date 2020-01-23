class OrthologGroupDescriptionsStanza < TogoStanza::Stanza::Base
  property :title do |cluster_id|
    "Cluster ID #{cluster_id}"
  end

  property :param_cluster_id do |cluster_id|
    cluster_id
  end

  property :adjust_iframe_height_script do
    "260"
  end

  property :features do |cluster_id, dataset|
    query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
      PREFIX mgfo: <http://purl.jp/bio/11/mgfo#>
      PREFIX orth: <http://purl.jp/bio/11/orth#>
      PREFIX dct: <http://purl.org/dc/terms/>

      SELECT ?label ?desc ?dist
         (COUNT(DISTINCT ?member) AS ?num)
      WHERE {
      ?group a orth:OrthologGroup ;
           rdfs:label ?label ;
           orth:inDataset mbgdr:#{dataset} ;
           dct:identifier "#{cluster_id}";
           dct:description ?desc ;
           orth:member ?member .
      }
    SPARQL
  end
end
