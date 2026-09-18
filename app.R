library(shiny)
library(visNetwork)
library(jsonlite)


# Read the graph data and legend from JSON.
graph <- fromJSON("graph.json")
legend <- graph$legend

nodes <- data.frame(
  id = graph$nodes$id,
  label = graph$nodes$label,
  title = graph$nodes$title,
  group = graph$nodes$group,
  level = graph$nodes$level,
  stringsAsFactors = FALSE
)

edges <- data.frame(
  from = graph$edges$from,
  to = graph$edges$to,
  arrows = "to",
  dashes = graph$edges$dashed,
  stringsAsFactors = FALSE
)

legend_nodes <- data.frame(
  id = paste0("legend_", legend$group),
  label = legend$label,
  title = paste0(legend$label, " (", legend$group, ")"),
  shape = "dot",
  color = legend$color,
  stringsAsFactors = FALSE
)

ui <- fluidPage(
  titlePanel("Course prerequisite graph"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "layout",
        label = "Layout",
        choices = c(
          "Flexible force-directed" = "free",
          "Left-to-right by course level" = "hierarchical"
        ),
        selected = "free"
      ),
      checkboxInput(
        inputId = "physics",
        label = "Enable physics",
        value = TRUE
      ),
      actionButton("stabilize", "Stabilize layout"),
      tags$hr(),
      helpText(
        "Drag courses to reposition them. Use the mouse wheel to zoom and drag the background to pan."
      )
    ),
    mainPanel(
      visNetworkOutput("network", height = "800px")
    )
  )
)

server <- function(input, output, session) {
  output$network <- renderVisNetwork({
    network <- visNetwork(
      nodes,
      edges,
      width = "100%",
      height = "800px"
    ) %>%
      visEdges(arrows = "to") %>%
      visInteraction(dragNodes = TRUE, dragView = TRUE, zoomView = TRUE) %>%
      visOptions(
        highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
        nodesIdSelection = TRUE
      ) %>%
      visPhysics(
        enabled = input$physics,
        solver = "forceAtlas2Based",
        forceAtlas2Based = list(
          gravitationalConstant = -80,
          centralGravity = 0.01,
          springLength = 160,
          springConstant = 0.04,
          damping = 0.4
        ),
        stabilization = list(enabled = TRUE, iterations = 300)
      )

    for (i in seq_len(nrow(legend))) {
      network <- network %>%
        visGroups(groupname = legend$group[i], color = legend$color[i])
    }

    if (input$layout == "hierarchical") {
      network <- network %>%
        visHierarchicalLayout(
          direction = "LR",
          sortMethod = "directed",
          levelSeparation = 180,
          nodeSpacing = 120
        )
    } else {
      network <- network %>% visLayout(randomSeed = 123)
    }

    network %>%
      visLegend(
        addNodes = legend_nodes,
        useGroups = FALSE,
        position = "right",
        width = 0.2,
        main = "Class groups"
      )
  })

  observeEvent(input$stabilize, {
    visNetworkProxy("network") %>% visStabilize(iterations = 300)
  })
}

shinyApp(ui = ui, server = server)
