library(visNetwork)
library(jsonlite)


# Read in the graph
graph <- fromJSON("graph.json")
legend <- graph$legend

# Create the nodes
nodes <- data.frame(
  id = graph$nodes$id,
  label = graph$nodes$label,
  title = graph$nodes$title,
  group = graph$nodes$group,
  level = graph$nodes$level,
  stringsAsFactors = FALSE
)

# Create the edges
edges <- data.frame(
  from = graph$edges$from,
  to = graph$edges$to,
  arrows = "to",
  stringsAsFactors = FALSE
)

# Use the legend metadata to create legend entries for visNetwork.
legend_nodes <- data.frame(
  id = paste0("legend_", legend$group),
  label = legend$label,
  title = paste(legend$label, "(", legend$group, ")"),
  shape = "dot",
  color = legend$color,
  stringsAsFactors = FALSE
)

# Create the network and apply the legend colors to matching groups.
network <- visNetwork(nodes, edges, width = "100%", height = "800px") %>%
  visEdges(arrows = "to") %>%
  visInteraction(dragNodes = TRUE, dragView = TRUE, zoomView = TRUE)

for (i in seq_len(nrow(legend))) {
  network <- network %>%
    visGroups(groupname = legend$group[i], color = legend$color[i])
}

network %>%
  visLegend(
    addNodes = legend_nodes,
    useGroups = FALSE,
    position = "right",
    width = 0.2,
    main = "Class groups"
  )
