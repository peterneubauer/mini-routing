require "rubygems"
require 'neo4j'
include Java
require 'populate'

Dir["lib/*.jar"].each { |jar| 
  puts jar
  require jar 
}


AStar = Java::org.neo4j.graphalgo.shortestpath.AStar
RelationshipExpander = Java::org.neo4j.graphalgo.RelationshipExpander
Direction = Java::org.neo4j.graphdb.Direction
DoubleEvaluator = Java::org.neo4j.graphalgo.shortestpath.std.DoubleEvaluator
EstimateEvaluator = Java::org.neo4j.graphalgo.shortestpath.EstimateEvaluator


class GeoCostEvaluator
  include org.neo4j.graphalgo.shortestpath.EstimateEvaluator
  def getCost(node, goal)
    distance(node, goal)
  end
end



sp = AStar.new( Neo4j::instance, RelationshipExpander.forTypes( 'Waypoint#roads', Direction.BOTH),
				        DoubleEvaluator.new("weight") , GeoCostEvaluator.new)