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
    #query('http://sparql.nibb.ac.jp/sparql', <<-SPARQL.strip_heredoc)
    query('http://mbgd.genome.ad.jp:7050/sparql', <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>
      PREFIX orthology: <http://purl.org/net/orth#>
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX void: <http://rdfs.org/ns/void#>

      SELECT ?label ?desc (COUNT(DISTINCT ?member) AS ?num)
      WHERE {
      ?group a orthology:OrthologsCluster ;
           rdfs:label ?label ;
           void:inDataset mbgdr:#{dataset} ;
           dct:identifier "#{cluster_id}";
           dct:description ?desc ;
           orthology:hasHomologous ?member .
      }
    SPARQL
  end
end
