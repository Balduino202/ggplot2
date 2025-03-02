% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geom-abline.r, R/geom-hline.r, R/geom-vline.r
\name{geom_abline}
\alias{geom_abline}
\alias{geom_hline}
\alias{geom_vline}
\title{Reference lines: horizontal, vertical, and diagonal}
\usage{
geom_abline(
  mapping = NULL,
  data = NULL,
  ...,
  slope,
  intercept,
  na.rm = FALSE,
  show.legend = NA
)

geom_hline(
  mapping = NULL,
  data = NULL,
  ...,
  yintercept,
  na.rm = FALSE,
  show.legend = NA
)

geom_vline(
  mapping = NULL,
  data = NULL,
  ...,
  xintercept,
  na.rm = FALSE,
  show.legend = NA
)
}
\arguments{
\item{mapping}{Set of aesthetic mappings created by \code{\link[=aes]{aes()}} or \code{\link[=aes_]{aes_()}}.}

\item{data}{The data to be displayed in this layer. There are three
options:

If \code{NULL}, the default, the data is inherited from the plot
data as specified in the call to \code{\link[=ggplot]{ggplot()}}.

A \code{data.frame}, or other object, will override the plot
data. All objects will be fortified to produce a data frame. See
\code{\link[=fortify]{fortify()}} for which variables will be created.

A \code{function} will be called with a single argument,
the plot data. The return value must be a \code{data.frame}, and
will be used as the layer data. A \code{function} can be created
from a \code{formula} (e.g. \code{~ head(.x, 10)}).}

\item{...}{Other arguments passed on to \code{\link[=layer]{layer()}}. These are
often aesthetics, used to set an aesthetic to a fixed value, like
\code{colour = "red"} or \code{size = 3}. They may also be parameters
to the paired geom/stat.}

\item{na.rm}{If \code{FALSE}, the default, missing values are removed with
a warning. If \code{TRUE}, missing values are silently removed.}

\item{show.legend}{logical. Should this layer be included in the legends?
\code{NA}, the default, includes if any aesthetics are mapped.
\code{FALSE} never includes, and \code{TRUE} always includes.
It can also be a named logical vector to finely select the aesthetics to
display.}

\item{xintercept, yintercept, slope, intercept}{Parameters that control the
position of the line. If these are set, \code{data}, \code{mapping} and
\code{show.legend} are overridden.}
}
\description{
These geoms add reference lines (sometimes called rules) to a plot, either
horizontal, vertical, or diagonal (specified by slope and intercept).
These are useful for annotating plots.
}
\details{
These geoms act slightly differently from other geoms. You can supply the
parameters in two ways: either as arguments to the layer function,
or via aesthetics. If you use arguments, e.g.
\code{geom_abline(intercept = 0, slope = 1)}, then behind the scenes
the geom makes a new data frame containing just the data you've supplied.
That means that the lines will be the same in all facets; if you want them
to vary across facets, construct the data frame yourself and use aesthetics.

Unlike most other geoms, these geoms do not inherit aesthetics from the plot
default, because they do not understand x and y aesthetics which are
commonly set in the plot. They also do not affect the x and y scales.
}
\section{Aesthetics}{

These geoms are drawn using with \code{\link[=geom_line]{geom_line()}} so support the
same aesthetics: \code{alpha}, \code{colour}, \code{linetype} and
\code{linewidth}. They also each have aesthetics that control the position of
the line:
\itemize{
\item \code{geom_vline()}: \code{xintercept}
\item \code{geom_hline()}: \code{yintercept}
\item \code{geom_abline()}: \code{slope} and \code{intercept}
}
}

\examples{
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()

# Fixed values
p + geom_vline(xintercept = 5)
p + geom_vline(xintercept = 1:5)
p + geom_hline(yintercept = 20)

p + geom_abline() # Can't see it - outside the range of the data
p + geom_abline(intercept = 20)

# Calculate slope and intercept of line of best fit
coef(lm(mpg ~ wt, data = mtcars))
p + geom_abline(intercept = 37, slope = -5)
# But this is easier to do with geom_smooth:
p + geom_smooth(method = "lm", se = FALSE)

# To show different lines in different facets, use aesthetics
p <- ggplot(mtcars, aes(mpg, wt)) +
  geom_point() +
  facet_wrap(~ cyl)

mean_wt <- data.frame(cyl = c(4, 6, 8), wt = c(2.28, 3.11, 4.00))
p + geom_hline(aes(yintercept = wt), mean_wt)

# You can also control other aesthetics
ggplot(mtcars, aes(mpg, wt, colour = wt)) +
  geom_point() +
  geom_hline(aes(yintercept = wt, colour = wt), mean_wt) +
  facet_wrap(~ cyl)
}
\seealso{
See \code{\link[=geom_segment]{geom_segment()}} for a more general approach to
adding straight line segments to a plot.
}
