require 'net/http'
require 'uri'
require "rubygems"
require 'neo4j'
include Java

Dir["lib/*.jar"].each { |jar| 
  require jar 
}
APP_ID = 'JzJ0LQ_V34EWH5agHt7TZxD0Eqz2CoEkX.xAM9y8PeAIjYALdy4C9Psh0pcZ1t6dpPf9zxXXjICw'
RADIUS_EARTH = 6371*1000 #in meters

#shortcuts for verbose Java stuff
AStar = Java::org.neo4j.graphalgo.shortestpath.AStar
RelationshipExpander = Java::org.neo4j.graphalgo.RelationshipExpander
Direction = Java::org.neo4j.graphdb.Direction
DynamicRelationshipType = Java::org.neo4j.graphdb.DynamicRelationshipType
DoubleEvaluator = Java::org.neo4j.graphalgo.shortestpath.std.DoubleEvaluator
EstimateEvaluator = Java::org.neo4j.graphalgo.shortestpath.EstimateEvaluator

#implements a Java Interface
class GeoCostEvaluator
  include org.neo4j.graphalgo.shortestpath.EstimateEvaluator
  def getCost(node, goal)
    distance(node.getProperty("lat"), node.getProperty("lon"), goal.getProperty("lat"),goal.getProperty("lon"))
  end
end


#calculates a geodetic distance between two spatial points
def distance(start_lat, start_lon, other_lat, other_lon)
  latitude1 = start_lat.to_f * Math::PI/180 #in radian
  longitude1 = start_lon.to_f * Math::PI/180 #in radian
  latitude2 = other_lat.to_f * Math::PI/180 #in radian
  longitude2 = other_lon.to_f * Math::PI/180 #in radian
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

#domain model
class Road
  include Neo4j::RelationshipMixin
  
  property :cost
end

class Waypoint
  include Neo4j::NodeMixin
  
  property :lat, :lon, :name
  index :name
  has_n(:roads).to(Waypoint).relationship(Road)
  
  #we right now just calculate the straight distance as cost
  def connect(other)
    self.roads.new(other).update(:cost => distance(self.lat, self.lon, other.lat, other.lon))
  end
  def to_s
    "Waypoint, #{name}, lon=#{lon}, lat=#{lat}"
  end
end


def create_waypoint(city, state)
  url = "http://local.yahooapis.com/MapsService/V1/geocode?appid=#{APP_ID}"
  res = Net::HTTP.get(URI.parse( URI.escape(url + "&state=#{state}&city=#{city}") ))
  
  lat = res.slice(/Latitude\>(.*)\<\/Latitude/,1)
  lon = res.slice(/Longitude\>(.*)\<\/Longitude/,1)
  point = Waypoint.new :name=>city, :lon=>lon, :lat=>lat
  puts point
  point
end

#populating the routing test
Neo4j::Transaction.run do
  NYC = create_waypoint('New York', 'New York')
  KAN = create_waypoint('Kansas City', 'Kansas')
  SFE = create_waypoint('Santa Fe', 'New Mexico')
  SEA = create_waypoint('Seattle', 'Washington')
  SF = create_waypoint('San Francisco', 'CA')
  NYC.connect(KAN)
  NYC.connect(SEA)
  SEA.connect(SF)
  KAN.connect(SFE)
  SFE.connect(SF)
end

#Finding the route

#Java classes used
sp = AStar.new( Neo4j::instance, RelationshipExpander.forTypes( DynamicRelationshipType.withName('Waypoint#roads'), Direction::BOTH),
				        DoubleEvaluator.new("cost") , GeoCostEvaluator.new)
path = sp.findSinglePath(NYC._java_node, SF._java_node)
nodes = path.getNodes.iterator
until !nodes.hasNext() do 
  puts nodes.next.getProperty('name')
end