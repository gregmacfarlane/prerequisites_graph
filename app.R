library(shiny)
library(visNetwork)
library(jsonlite)


graph_files <- c(
  "25-26" = "graph_2526.json",
  "26-27" = "graph_2627.json"
)

read_graph <- function(program_year) {
  graph <- fromJSON(graph_files[[program_year]])
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

  list(nodes = nodes, edges = edges, legend = legend, legend_nodes = legend_nodes)
}

ui <- fluidPage(
  titlePanel("Course prerequisite graph"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "program_year",
        label = "Program version",
        choices = c(
          "2025-2026" = "25-26",
          "2026-2027" = "26-27"
        ),
        selected = "25-26"
      ),
      uiOutput("requirement_panel"),
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
  output$requirement_panel <- renderUI({
    current_graph <- read_graph(input$program_year)
    capstone_nodes <- current_graph$nodes[current_graph$nodes$group == "CAPSTONE", , drop = FALSE]

    capstone_ids <- capstone_nodes$id
    capstone_predecessors <- unique(
      current_graph$edges$to[
        current_graph$edges$from %in% capstone_ids &
          current_graph$edges$to %in% capstone_ids
      ]
    )
    starting_capstone_ids <- setdiff(capstone_ids, capstone_predecessors)
    starting_capstones <- capstone_nodes$label[
      match(starting_capstone_ids, capstone_nodes$id)
    ]

    requirement <- if (length(starting_capstones) > 0) {
      requirement_text <- if (input$program_year == "26-27") {
        "12 hours of CE Breadth and one CE Design class must be completed before starting "
      } else {
        "12 hours of CE Breadth must be completed before starting "
      }

      paste0(
        "For the ", input$program_year, " program, ",
        requirement_text,
        paste(starting_capstones, collapse = " or "), "."
      )
    } else {
      paste0(
        "For the ", input$program_year,
        " program, 12 hours of CE Breadth must be completed before starting Capstone."
      )
    }

    wellPanel(
      h4("Capstone requirement"),
      p(requirement)
    )
  })

  output$network <- renderVisNetwork({
    current_graph <- read_graph(input$program_year)
    nodes <- current_graph$nodes
    edges <- current_graph$edges
    legend <- current_graph$legend
    legend_nodes <- current_graph$legend_nodes

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
