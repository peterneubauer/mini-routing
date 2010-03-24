require "rubygems"
require 'neo4j'
include Java

Dir["lib/*.jar"].each { |jar| 
  puts jar
  require jar 
}


AStar = Java::org.neo4j.graphalgo.shortestpath.AStar
RelationshipExpander = Java::org.neo4j.graphalgo.RelationshipExpander
Direction = Java::org.neo4j.graphdb.Direction
DoubleEvaluator = Java::org.neo4j.graphalgo.shortestpath.DoubleEvaluator
EstimateEvaluator = Java::org.neo4j.graphalgo.shortestpath.EstimateEvaluator

def distance(start, other)
  latitude1 = start.lat.to_f * Math::PI/180 #in radian
  longitude1 = start.lon.to_f * Math::PI/180 #in radian
  latitude2 = other.lat.to_f * Math::PI/180 #in radian
  longitude2 = other.lon.to_f * Math::PI/180 #in radian
  cLa1 = Math.cos( latitude1 );
  x_A = RADIUS_EARTH * cLa1 * Math.cos( longitude1 )
  y_A = RADIUS_EARTH * cLa1 * Math.sin( longitude1 )
  z_A = RADIUS_EARTH * Math.sin( latitude1 );

  cLa2 = Math.cos( latitude2 );
  x_B = RADIUS_EARTH * cLa2 * Math.cos( longitude2 )
  y_B = RADIUS_EARTH * cLa2 * Math.sin( longitude2 )
  z_B = RADIUS_EARTH * Math.sin( latitude2 )
  
  #in meters
  distance = Math.sqrt( ( x_A - x_B ) * ( x_A - x_B ) + ( y_A - y_B ) * ( y_A - y_B ) + ( z_A - z_B ) * ( z_A - z_B ) )
end

class GeoCostEvaluator
  include EstimateEvaluator
  def getCost(node, goal)
    distance(node, goal)
  end
end



sp = AStar.new( Neo4j::instance, RelationshipExpander.forTypes( 'Waypoint#roads', Direction.BOTH),
				        DoubleEvaluator.new("weight") , GeoCostEvaluator.new)