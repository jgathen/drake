% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vis_drake_graph.R
\name{vis_drake_graph}
\alias{vis_drake_graph}
\alias{drake_graph}
\title{Show an interactive visual network representation
of your drake project.}
\usage{
vis_drake_graph(config = drake::read_drake_config(), file = character(0),
  selfcontained = FALSE, build_times = "build", digits = 3,
  targets_only = FALSE, split_columns = NULL, font_size = 20,
  layout = "layout_with_sugiyama", main = NULL, direction = "LR",
  hover = TRUE, navigationButtons = TRUE, from = NULL, mode = c("out",
  "in", "all"), order = NULL, subset = NULL, ncol_legend = 1,
  full_legend = TRUE, make_imports = TRUE, from_scratch = FALSE, ...)
}
\arguments{
\item{config}{a \code{\link[=drake_config]{drake_config()}} configuration list.
You can get one as a return value from \code{\link[=make]{make()}} as well.}

\item{file}{Name of HTML file to save the graph.
If \code{NULL} or \code{character(0)},
no file is saved and the graph is rendered and displayed within R.}

\item{selfcontained}{logical, whether
to save the \code{file} as a self-contained
HTML file (with external resources base64 encoded) or a file with
external resources placed in an adjacent directory. If \code{TRUE},
pandoc is required.}

\item{build_times}{character string or logical.
If character, the choices are
1. \code{"build"}: runtime of the command plus the time
it take to store the target or import.
2. \code{"command"}: just the runtime of the command.
3. \code{"none"}: no build times.
If logical, \code{build_times} selects whether to show the
times from `build_times(..., type = "build")`` or use
no build times at all. See \code{\link[=build_times]{build_times()}} for details.}

\item{digits}{number of digits for rounding the build times}

\item{targets_only}{logical,
whether to skip the imports and only include the
targets in the workflow plan.}

\item{split_columns}{logical, deprecated.}

\item{font_size}{numeric, font size of the node labels in the graph}

\item{layout}{name of an igraph layout to use,
such as 'layout_with_sugiyama'
or 'layout_as_tree'.
Be careful with 'layout_as_tree': the graph is a directed
acyclic graph, but not necessarily a tree.}

\item{main}{character string, title of the graph}

\item{direction}{an argument to \code{\link[visNetwork:visHierarchicalLayout]{visNetwork::visHierarchicalLayout()}}
indicating the direction of the graph.
Options include 'LR', 'RL', 'DU', and 'UD'.
At the time of writing this, the letters must be capitalized,
but this may not always be the case ;) in the future.}

\item{hover}{logical, whether to show the command that generated the target
when you hover over a node with the mouse. For imports, the label does not
change with hovering.}

\item{navigationButtons}{logical, whether to add navigation buttons with
\code{visNetwork::visInteraction(navigationButtons = TRUE)}}

\item{from}{Optional collection of target/import names.
If \code{from} is nonempty,
the graph will restrict itself to
a neighborhood of \code{from}.
Control the neighborhood with
\code{mode} and \code{order}.}

\item{mode}{Which direction to branch out in the graph
to create a neighborhood around \code{from}.
Use \code{"in"} to go upstream,
\code{"out"} to go downstream,
and \code{"all"} to go both ways and disregard
edge direction altogether.}

\item{order}{How far to branch out to create
a neighborhood around \code{from} (measured
in the number of nodes). Defaults to
as far as possible.}

\item{subset}{Optional character vector of of target/import names.
Subset of nodes to display in the graph.
Applied after \code{from}, \code{mode}, and \code{order}.
Be advised: edges are only kept for adjacent nodes in \code{subset}.
If you do not select all the intermediate nodes,
edges will drop from the graph.}

\item{ncol_legend}{number of columns in the legend nodes.
To remove the legend entirely, set \code{ncol_legend} to \code{NULL} or \code{0}.}

\item{full_legend}{logical. If \code{TRUE}, all the node types
are printed in the legend. If \code{FALSE}, only the
node types used are printed in the legend.}

\item{make_imports}{logical, whether to make the imports first.
Set to \code{FALSE} to increase speed and risk using obsolete information.}

\item{from_scratch}{logical, whether to assume all the targets
will be made from scratch on the next \code{\link[=make]{make()}}.
Makes all targets outdated, but keeps information about
build progress in previous \code{\link[=make]{make()}}s.}

\item{...}{arguments passed to \code{\link[=visNetwork]{visNetwork()}}.}
}
\value{
A visNetwork graph.
}
\description{
To save time for repeated plotting,
this function is divided into
\code{\link[=drake_graph_info]{drake_graph_info()}} and \code{\link[=render_drake_graph]{render_drake_graph()}}.
}
\examples{
\dontrun{
test_with_dir("Quarantine side effects.", {
config <- load_mtcars_example() # Get the code with drake_example("mtcars").
# Plot the network graph representation of the workflow.
vis_drake_graph(config, width = '100\%') # The width is passed to visNetwork
config <- make(my_plan) # Run the project, build the targets.
vis_drake_graph(config) # The red nodes from before are now green.
# Plot a subgraph of the workflow.
vis_drake_graph(
  config,
  from = c("small", "reg2"),
  to = "summ_regression2_small"
)
})
}
}
\seealso{
\code{\link[=build_drake_graph]{build_drake_graph()}}
}
