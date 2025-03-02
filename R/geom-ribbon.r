#' Ribbons and area plots
#'
#' For each x value, `geom_ribbon()` displays a y interval defined
#' by `ymin` and `ymax`. `geom_area()` is a special case of
#' `geom_ribbon()`, where the `ymin` is fixed to 0 and `y` is used instead
#' of `ymax`.
#'
#' An area plot is the continuous analogue of a stacked bar chart (see
#' [geom_bar()]), and can be used to show how composition of the
#' whole varies over the range of x. Choosing the order in which different
#' components is stacked is very important, as it becomes increasing hard to
#' see the individual pattern as you move up the stack. See
#' [position_stack()] for the details of stacking algorithm.
#'
#' @eval rd_orientation()
#'
#' @eval rd_aesthetics("geom", "ribbon")
#' @seealso
#'   [geom_bar()] for discrete intervals (bars),
#'   [geom_linerange()] for discrete intervals (lines),
#'   [geom_polygon()] for general polygons
#' @inheritParams layer
#' @inheritParams geom_bar
#' @param outline.type Type of the outline of the area; `"both"` draws both the
#'   upper and lower lines, `"upper"`/`"lower"` draws the respective lines only.
#'   `"full"` draws a closed polygon around the area.
#' @export
#' @examples
#' # Generate data
#' huron <- data.frame(year = 1875:1972, level = as.vector(LakeHuron))
#' h <- ggplot(huron, aes(year))
#'
#' h + geom_ribbon(aes(ymin=0, ymax=level))
#' h + geom_area(aes(y = level))
#'
#' # Orientation cannot be deduced by mapping, so must be given explicitly for
#' # flipped orientation
#' h + geom_area(aes(x = level, y = year), orientation = "y")
#'
#' # Add aesthetic mappings
#' h +
#'   geom_ribbon(aes(ymin = level - 1, ymax = level + 1), fill = "grey70") +
#'   geom_line(aes(y = level))
geom_ribbon <- function(mapping = NULL, data = NULL,
                        stat = "identity", position = "identity",
                        ...,
                        na.rm = FALSE,
                        orientation = NA,
                        show.legend = NA,
                        inherit.aes = TRUE,
                        outline.type = "both") {
  outline.type <- arg_match0(outline.type, c("both", "upper", "lower", "full"))

  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomRibbon,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list2(
      na.rm = na.rm,
      orientation = orientation,
      outline.type = outline.type,
      ...
    )
  )
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
GeomRibbon <- ggproto("GeomRibbon", Geom,
  default_aes = aes(colour = NA, fill = "grey20", linewidth = 0.5, linetype = 1,
    alpha = NA),

  required_aes = c("x|y", "ymin|xmin", "ymax|xmax"),

  setup_params = function(data, params) {
    params$flipped_aes <- has_flipped_aes(data, params, range_is_orthogonal = TRUE)
    params
  },

  extra_params = c("na.rm", "orientation"),

  setup_data = function(data, params) {
    data$flipped_aes <- params$flipped_aes
    data <- flip_data(data, params$flipped_aes)

    if (is.null(data$ymin) && is.null(data$ymax)) {
      cli::cli_abort("Either {.field {flipped_names(params$flipped_aes)$ymin}} or {.field {flipped_names(params$flipped_aes)$ymax}} must be given as an aesthetic.")
    }
    data <- data[order(data$PANEL, data$group, data$x), , drop = FALSE]
    data$y <- data$ymin %||% data$ymax
    flip_data(data, params$flipped_aes)
  },

  draw_key = draw_key_polygon,

  handle_na = function(data, params) {
    data
  },

  draw_group = function(data, panel_params, coord, lineend = "butt",
                        linejoin = "round", linemitre = 10, na.rm = FALSE,
                        flipped_aes = FALSE, outline.type = "both") {
    data <- flip_data(data, flipped_aes)
    if (na.rm) data <- data[stats::complete.cases(data[c("x", "ymin", "ymax")]), ]
    data <- data[order(data$group), ]

    # Check that aesthetics are constant
    aes <- unique(data[c("colour", "fill", "linewidth", "linetype", "alpha")])
    if (nrow(aes) > 1) {
      cli::cli_abort("Aesthetics can not vary along a ribbon")
    }
    aes <- as.list(aes)

    # Instead of removing NA values from the data and plotting a single
    # polygon, we want to "stop" plotting the polygon whenever we're
    # missing values and "start" a new polygon as soon as we have new
    # values.  We do this by creating an id vector for polygonGrob that
    # has distinct polygon numbers for sequences of non-NA values and NA
    # for NA values in the original data.  Example: c(NA, 2, 2, 2, NA, NA,
    # 4, 4, 4, NA)
    missing_pos <- !stats::complete.cases(data[c("x", "ymin", "ymax")])
    ids <- cumsum(missing_pos) + 1
    ids[missing_pos] <- NA

    data <- unclass(data) #for faster indexing

    # The upper line and lower line need to processed separately (#4023)
    positions_upper <- new_data_frame(list(
      x = data$x,
      y = data$ymax,
      id = ids
    ))

    positions_lower <- new_data_frame(list(
      x = rev(data$x),
      y = rev(data$ymin),
      id = rev(ids)
    ))

    positions_upper <- flip_data(positions_upper, flipped_aes)
    positions_lower <- flip_data(positions_lower, flipped_aes)

    munched_upper <- coord_munch(coord, positions_upper, panel_params)
    munched_lower <- coord_munch(coord, positions_lower, panel_params)

    munched_poly <- rbind(munched_upper, munched_lower)

    is_full_outline <- identical(outline.type, "full")
    g_poly <- polygonGrob(
      munched_poly$x, munched_poly$y, id = munched_poly$id,
      default.units = "native",
      gp = gpar(
        fill = alpha(aes$fill, aes$alpha),
        col = if (is_full_outline) aes$colour else NA,
        lwd = if (is_full_outline) aes$linewidth * .pt else 0,
        lty = if (is_full_outline) aes$linetype else 1,
        lineend = lineend,
        linejoin = linejoin,
        linemitre = linemitre
      )
    )

    if (is_full_outline) {
      return(ggname("geom_ribbon", g_poly))
    }

    # Increment the IDs of the lower line so that they will be drawn as separate lines
    munched_lower$id <- munched_lower$id + max(ids, na.rm = TRUE)

    munched_lines <- switch(outline.type,
      both = rbind(munched_upper, munched_lower),
      upper = munched_upper,
      lower = munched_lower,
      cli::cli_abort(c(
        "invalid {.arg outline.type}: {.val {outline.type}}",
        "i" = "use either {.val upper}, {.val lower}, or {.val both}"
      ))
    )
    g_lines <- polylineGrob(
      munched_lines$x, munched_lines$y, id = munched_lines$id,
      default.units = "native",
      gp = gpar(
        col = aes$colour,
        lwd = aes$linewidth * .pt,
        lty = aes$linetype,
        lineend = lineend,
        linejoin = linejoin,
        linemitre = linemitre
      )
    )

    ggname("geom_ribbon", grobTree(g_poly, g_lines))
  },

  rename_size = TRUE
)

#' @rdname geom_ribbon
#' @export
geom_area <- function(mapping = NULL, data = NULL, stat = "identity",
                      position = "stack", na.rm = FALSE, orientation = NA,
                      show.legend = NA, inherit.aes = TRUE, ...,
                      outline.type = "upper") {
  outline.type <- arg_match0(outline.type, c("both", "upper", "lower", "full"))

  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomArea,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list2(
      na.rm = na.rm,
      orientation = orientation,
      outline.type = outline.type,
      ...
    )
  )
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
GeomArea <- ggproto("GeomArea", GeomRibbon,
  default_aes = aes(colour = NA, fill = "grey20", linewidth = 0.5, linetype = 1,
    alpha = NA),

  required_aes = c("x", "y"),

  setup_params = function(data, params) {
    params$flipped_aes <- has_flipped_aes(data, params, ambiguous = TRUE)
    params
  },

  setup_data = function(data, params) {
    data$flipped_aes <- params$flipped_aes
    data <- flip_data(data, params$flipped_aes)
    data <- transform(data[order(data$PANEL, data$group, data$x), ], ymin = 0, ymax = y)
    flip_data(data, params$flipped_aes)
  }
)
