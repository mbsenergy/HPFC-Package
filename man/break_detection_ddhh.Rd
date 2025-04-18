% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/break_detection.R
\name{break_detection_ddhh}
\alias{break_detection_ddhh}
\title{Detect Breakpoints in Hourly Time Series Data}
\usage{
break_detection_ddhh(DT)
}
\arguments{
\item{DT}{A \code{data.table} containing at least three columns:
\itemize{
\item \code{date}: Date of the observation.
\item \code{hour}: Hour of the day for each observation.
\item \code{value}: The corresponding value for each date and hour.
}}
}
\value{
A \code{data.table} with the following columns:
\itemize{
\item \code{date}: The original date.
\item \code{hour}: The original hour.
\item \code{value}: The original value.
\item \code{break_group_p}: A grouping variable for the detected periods (breaks).
}
}
\description{
This function detects breakpoints in hourly time series data. It computes the deviation of the
sample values (\code{value}) from the daily mean, applies a changepoint detection algorithm to the
residuals (deviation from the mean), and assigns each observation to a break group based on detected
breakpoints. The function handles missing values using last observation carried forward (locf).
}
\details{
The function performs the following steps:
\itemize{
\item Calculates the deviation of each hourly value from the daily mean.
\item Applies the \code{changepoint} package to detect breakpoints in the residuals (deviations).
\item Assigns each observation to a break group based on the detected breakpoints.
\item Removes any non-essential columns from the data.table.
}
}
\examples{
# Example usage with a sample data.table `DT`
DT <- data.table(date = rep(as.Date("2020-01-01"), 24), 
                 hour = 0:23, 
                 value = rnorm(24))
result <- break_detection_ddhh(DT)

}
