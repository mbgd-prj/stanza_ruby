class OrthologGroupMembersInTreeStanza < TogoStanza::Stanza::Base
  property :greeting do
    'hello, world!'
  end
  property :param_cluster_id do |cluster_id|
    cluster_id
  end
  property :param_dataset do |dataset|
    dataset
  end
  resource :features do |cluster_id, dataset|
    query('http://sparql.nibb.ac.jp:8047/sparql', <<-SPARQL.strip_heredoc)
    PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>

SELECT ?o
WHERE {
    <http://mbgd.genome.ad.jp/rdf/resource/#{dataset}/cluster/#{cluster_id}> mbgd:newickTree ?o
}
SPARQL
end
end
