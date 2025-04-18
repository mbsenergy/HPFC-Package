% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrappers.R
\name{prepare_pwr}
\alias{prepare_pwr}
\title{Prepare Power Data for Modeling}
\usage{
prepare_pwr(list_inputs = list_inputs)
}
\arguments{
\item{list_inputs}{A list containing required datasets and parameters:
\itemize{
\item \code{LST_PARAMS}: A list of parameters, including \code{history_start} and \code{history_end} defining the time range.
\item \code{ENV_SPOT}: An environment containing \code{history_pwr}, a data.table with power price history.
\item \code{ENV_CODES}: An environment (not explicitly used in this function but kept for consistency).
}}
}
\value{
A list (\code{ENV_MODELS_PWR}) with the following elements:
\item{dt_pwr}{Filtered power price data (date, hour, value, RIC).}
\item{dt_pwr_filt_dd}{Power data after break detection and outlier removal (daily level).}
\item{dt_lt_param_pwr}{Detrended daily power data.}
\item{dt_pwr_filt_ddhh}{Power data after break detection and outlier removal (hourly level).}
\item{dt_hr_param_pwr}{Processed hourly power data without RIC.}
}
\description{
This function processes power price data for use in a regime-switching VAR-GARCH model.
It filters historical power prices, detects breaks, removes outliers, and applies detrending.
}
