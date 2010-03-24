require "rubygems"
require 'neo4j'

class Road
  include Neo4j::RelationshipMixin
  
  property :cost
end

class Waypoint
  include Neo4j::NodeMixin
  
  property :lat, :lon, :name
  index :name
  has_n(:roads).to(Waypoint).relationship(Road)
end


Neo4j::Transaction.run do
  NYC = Waypoint.new :name=>'NYC'
  SF = Waypoint.new :name=>'SF'
  
  NYC.roads.new(SF).update(:cost => 2000)
end