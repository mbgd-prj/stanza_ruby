class OrthologGroupMembersInEnvironmentsStanza < TogoStanza::Stanza::Base
  property :param_cluster_id do |cluster_id|
    cluster_id
  end
  property :param_dataset do |dataset|
    dataset
  end

  resource :tax_dis do |cluster_id, dataset|
  taxs = query("http://sparql.nibb.ac.jp/sparql", <<-SPARQL.strip_heredoc)
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX void: <http://rdfs.org/ns/void#>
PREFIX oo: <http://purl.org/net/orth#>
PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>

SELECT DISTINCT ?taxid
where { 
    ?group a oo:OrthologsCluster ;
           void:inDataset mbgdr:#{dataset} ;
           dct:identifier "#{cluster_id}";
           oo:hasHomologous ?member .
    ?member mbgd:organism ?organism .
    ?organism mbgd:taxon ?taxid .
} 
SPARQL

  tax_filter = '{'
    taxs.each_with_index do |entity, idx|
      s = entity[:taxid]
     #tax_filter << '(<http://purl.org/obo/owl/NCBITaxon#NCBITaxon_' << s.slice(s.rindex('/') + 1, s.length
      tax_filter << '(<'
      tax_filter << s
      tax_filter << '>)'
      tax_filter << ' ' if idx < taxs.size - 1
    end
    tax_filter << '}'

   tmpres = query("http://togogenome.org/sparql", <<-SPARQL.strip_heredoc)
   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX mccv: <http://purl.jp/bio/01/mccv#>
   PREFIX meo: <http://purl.jp/bio/11/meo/>
   SELECT COUNT(?env) AS ?count ?env ?env_label
   WHERE {
     SELECT DISTINCT ?tax ?env ?env_label
      WHERE {
        VALUES (?tax) #{tax_filter} 
        ?tax ^mccv:MCCV_000020/meo:MEO_0000437 ?meo .
        ?meo rdfs:subClassOf* ?env .
        ?env rdfs:label ?env_label .
        ?env meo:MEO_0000442 "2" .
        FILTER(! langMatches(lang(?env_label), "ja"))
       }
     }
    ORDER BY DESC(?count)
  
SPARQL

#   root = {:env => "http://www.w3.org/2002/07/owl#Thing", :env_label => "Thing", :definition => "root", :parent => "root"}
#   results.push(root)
#    results.map {|hash|
#      hash[:rank] = (hash[:rank]?hash[:rank].gsub('http://purl.uniprot.org/taxonomy/', ''):'')
#      hash.merge(
#        :tag_id => hash[:tax].split('/').last.split('#').last
#        #:link => "http://biointegra.jp/OpenID/?tax=" + hash[:tax].split('/').last.split('#').last
#      )
#    }


end
end
