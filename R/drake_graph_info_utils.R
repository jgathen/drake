append_build_times <- function(config) {
  with(config, {
    time_data <- build_times(
      digits = digits, cache = cache, type = build_times)
    timed <- intersect(time_data$item, nodes$id)
    if (!length(timed))
      return(nodes)
    time_labels <- as.character(time_data$elapsed)
    names(time_labels) <- time_data$item
    time_labels <- time_labels[timed]
    nodes[timed, "label"] <-
      paste(nodes[timed, "label"], time_labels, sep = "\n")
    nodes
  })
}

can_get_function <- function(x, envir) {
  tryCatch({
    is.function(eval(parse(text = x), envir = envir))
  },
  error = function(e) FALSE)
}

categorize_nodes <- function(config) {
  with(config, {
    nodes$status <- "imported"
    nodes[targets, "status"] <- "up to date"
    nodes[missing, "status"] <- "missing"
    nodes[outdated, "status"] <- "outdated"
    nodes[in_progress, "status"] <- "in progress"
    nodes[failed, "status"] <- "failed"
    nodes$type <- "object"
    nodes[is_file(nodes$id), "type"] <- "file"
    nodes[functions, "type"] <- "function"
    nodes
  })
}

configure_nodes <- function(config){
  rownames(config$nodes) <- config$nodes$label
  config$nodes <- categorize_nodes(config = config)
  config$nodes <- style_nodes(config = config)
  config$nodes <- resolve_levels(config = config)
  if (config$build_times != "none"){
    config$nodes <- append_build_times(config = config)
  }
  hover_text(config = config)
}

resolve_levels <- function(config){
  config$nodes$level <- level <- 0
  graph <- config$graph
  while (length(V(graph))){
    level <- level + 1
    leaves <- leaf_nodes(graph) %>%
      intersect(y = config$nodes$id)
    config$nodes[leaves, "level"] <- level
    graph <- igraph::delete_vertices(graph = graph, v = leaves)
  }
  config$nodes
}

#' @title Return the default title of the graph for
#'   [vis_drake_graph()].
#' @description For internal use only.
#' @export
#' @keywords internal
#' @seealso [drake_graph_info()], [vis_drake_graph()]
#' @return a character scalar with the default graph title for
#'   [vis_drake_graph()].
#' @param split_columns deprecated
#' @examples
#' default_graph_title()
default_graph_title <- function(split_columns = FALSE){
  "Dependency graph"
}

file_hover_text <- Vectorize(function(quoted_file, targets){
  unquoted_file <- drake_unquote(quoted_file)
  if (quoted_file %in% targets | !file.exists(unquoted_file))
    return(quoted_file)
  tryCatch({
    readLines(unquoted_file, n = 10, warn = FALSE) %>%
      paste(collapse = "\n") %>%
      crop_text(width = hover_text_width)
  },
  error = function(e) quoted_file,
  warning = function(w) quoted_file
  )
},
"quoted_file")

filter_legend_nodes <- function(legend_nodes, all_nodes){
  colors <- c(unique(all_nodes$color), color_of("object"))
  shapes <- unique(all_nodes$shape)
  ln <- legend_nodes
  ln[ln$color %in% colors & ln$shape %in% shapes, , drop = FALSE] # nolint
}

filtered_legend_nodes <- function(all_nodes, full_legend, font_size){
  legend_nodes <- legend_nodes(font_size = font_size)
  if (full_legend){
    legend_nodes
  } else {
    filter_legend_nodes(legend_nodes = legend_nodes, all_nodes = all_nodes)
  }
}

function_hover_text <- Vectorize(function(function_name, envir){
  tryCatch(
    eval(parse(text = function_name), envir = envir),
    error = function(e) function_name) %>%
    unwrap_function %>%
    deparse %>%
    paste(collapse = "\n") %>%
    crop_text(width = hover_text_width)
},
"function_name")

get_raw_node_category_data <- function(config){
  all_labels <- V(config$graph)$name
  config$outdated <- resolve_graph_outdated(config = config)
  config$imports <- setdiff(all_labels, config$plan$target)
  config$in_progress <- in_progress(cache = config$cache)
  config$failed <- failed(cache = config$cache)
  config$files <- parallel_filter(
    x = all_labels, f = is_file, jobs = config$jobs)
  config$functions <- parallel_filter(
    x = config$imports,
    f = function(x) can_get_function(x, envir = config$envir),
    jobs = config$jobs
  )
  config$missing <- parallel_filter(
    x = config$imports,
    f = function(x) missing_import(x, envir = config$envir),
    jobs = config$jobs
  )
  config
}

hover_text <- function(config) {
  with(config, {
    nodes$hover_label <- nodes$id
    import_files <- setdiff(files, targets)
    nodes[import_files, "hover_label"] <-
      file_hover_text(quoted_file = import_files, targets = targets)
    nodes[functions, "hover_label"] <-
      function_hover_text(function_name = functions, envir = config$envir)
    nodes[targets, "hover_label"] <-
      target_hover_text(targets = targets, plan = config$plan)
    nodes
  })
}

hover_text_width <- 250

#' @title Create the nodes data frame used in the legend
#'   of [vis_drake_graph()].
#' @export
#' @seealso [drake_palette()],
#'   [vis_drake_graph()],
#'   [drake_graph_info()]
#' @description Output a `visNetwork`-friendly
#' data frame of nodes. It tells you what
#' the colors and shapes mean
#' in [vis_drake_graph()].
#' @param font_size font size of the node label text
#' @return A data frame of legend nodes for [vis_drake_graph()].
#' @examples
#' \dontrun{
#' # Show the legend nodes used in vis_drake_graph().
#' # For example, you may want to inspect the color palette more closely.
#' visNetwork::visNetwork(nodes = legend_nodes())
#' }
legend_nodes <- function(font_size = 20) {
  out <- tibble(
    label = c(
      "Up to date",
      "Outdated",
      "In progress",
      "Failed",
      "Imported",
      "Missing",
      "Object",
      "Function",
      "File"
    ),
    color = color_of(c(
      "up_to_date",
      "outdated",
      "in_progress",
      "failed",
      "import_node",
      "missing_node",
      rep("generic", 3)
    )),
    shape = shape_of(c(
      rep("object", 7),
      "funct",
      "file"
    )),
    font.color = "black",
    font.size = font_size
  )
  out$id <- seq_len(nrow(out))
  out
}

missing_import <- function(x, envir) {
  missing_object <- !is_file(x) & is.null(envir[[x]]) & tryCatch({
    flexible_get(x, envir = envir)
    FALSE
  },
  error = function(e) TRUE)
  missing_file <- is_file(x) & !file.exists(drake_unquote(x))
  missing_object | missing_file
}

null_graph <- function() {
  nodes <- data.frame(id = 1, label = "Nothing to plot.")
  visNetwork::visNetwork(
    nodes = nodes,
    edges = data.frame(from = NA, to = NA),
    main = "Nothing to plot."
  )
}

resolve_graph_outdated <- function(config){
  if (config$from_scratch){
    config$outdated <- config$plan$target
  } else {
    config$outdated <- outdated(
      config = config,
      make_imports = config$make_imports
    )
  }
}

resolve_build_times <- function(build_times){
  if (is.logical(build_times)){
    warning(
      "The build_times argument to the visualization functions ",
      "should be a character string: \"build\", \"command\", or \"none\". ",
      "The change will be forced in a later version of `drake`. ",
      "see the `build_times()` function for details."
    )
    if (build_times){
      build_times <- "build"
    } else {
      build_times <- "none"
    }
  }
  build_times
}

style_nodes <- function(config) {
  with(config, {
    nodes$font.size <- font_size # nolint
    nodes[nodes$status == "imported", "color"] <- color_of("import_node")
    nodes[nodes$status == "in progress", "color"] <- color_of("in_progress")
    nodes[nodes$status == "failed", "color"] <- color_of("failed")
    nodes[nodes$status == "missing", "color"] <- color_of("missing_node")
    nodes[nodes$status == "outdated", "color"] <- color_of("outdated")
    nodes[nodes$status == "up to date", "color"] <- color_of("up_to_date")
    nodes[nodes$type == "object", "shape"] <- shape_of("object")
    nodes[nodes$type == "file", "shape"] <- shape_of("file")
    nodes[nodes$type == "function", "shape"] <- shape_of("funct")
    nodes
  })
}

target_hover_text <- function(targets, plan) {
  vapply(
    X = plan$command[plan$target %in% targets],
    FUN = function(text){
      crop_text(wrap_text(text), width = hover_text_width)
    },
    FUN.VALUE = character(1),
    USE.NAMES = FALSE
  )
}

trim_node_categories <- function(config){
  elts <- c(
    "failed", "files", "functions", "in_progress", "missing",
    "outdated", "targets"
  )
  for (elt in elts){
    config[[elt]] <- intersect(config[[elt]], config$nodes$id)
  }
  config
}
