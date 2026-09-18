library(visNetwork)
library(jsonlite)


# Read in the graph
graph <- fromJSON("graph.json")

# Create the nodes
nodes <- data.frame(
  id = graph$nodes$id,
  label = graph$nodes$label,
  title = graph$nodes$title,
  group = graph$nodes$group,
  level = graph$nodes$level
)

# Create the edges
edges <- data.frame(
  from = graph$edges$from,
  to = graph$edges$to,
  arrows = "to"
)

# Create the network
visNetwork(nodes, edges) 
