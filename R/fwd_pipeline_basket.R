#' Full Forward and Historical Data Pipeline for Power and Gas Markets
#'
#' Retrieves forward and spot data for a main power commodity, a basket of power and gas commodities,
#' and CO2 contracts if included, using the Eikon API via the `eikondata` package.
#'
#' @param commodity_main Character. Main power commodity to model (e.g., `"Germany"`).
#' @param commodity_basket Character vector. Basket of additional power/gas commodities (e.g., `c("France", "Italy", "TTF", "CO2")`).
#' @param start_train Date. Start of historical training data period.
#' @param end_train Date. End of historical training data period.
#' @param start_horizon Date. Start of forward data retrieval period.
#' @param end_horizon Date. End of forward data retrieval period.
#'
#' @return A named list with two elements:
#' \describe{
#'   \item{list_fwds}{Named list of forward data tables:
#'     \itemize{
#'       \item `main_inputs_fwd`: Main power forward curve.
#'       \item `main_inputs_fwd_gas`: TTF gas forward curve.
#'       \item `basketpwr_inputs_fwd`: Basket power forward curves.
#'       \item `basketgas_inputs_fwd`: Basket gas forward curves.
#'       \item `dt_co2_expanded`: Monthly interpolated CO2 forward prices (if CO2 in basket).
#'     }}
#'   \item{list_history}{Named list of historical spot data:
#'     \itemize{
#'       \item `history_main`: Main power spot prices.
#'       \item `history_ttf`: TTF spot prices.
#'       \item `history_basket_pwr`: Basket power spot prices.
#'       \item `history_basket_gas`: Basket gas spot prices.
#'     }}
#' }
#'
#' @details
#' The function queries Reuters/Eikon API using the `eikondata` package. Forward and spot data are fetched
#' for both power and gas products depending on the input basket. CO2 contracts are also handled specially
#' through interpolated values by year-month. Uses internal `prepare_fwd()` and `retrieve_spot()` helpers.
#'
#' @import data.table
#' @importFrom lubridate year
#' @import eikondata 
#' @export
get_data_pipeline = function(commodity_main, commodity_basket, start_train, end_train, start_horizon, end_horizon) {
    
    ## FWDS
    main_inputs_fwd = prepare_fwd(
        fwd_pwr_code = commodity_main,
        fwd_gas_code = NULL,
        start_date = start_horizon,
        end_date = end_horizon,
        model_type = 'PWR',
        forecast_source = 'FWD',
        archive = 'NO',
        manual_pwr = NULL,
        manual_gas = NULL,
        reuters_key = Sys.getenv('REUTERS_KEY')
    )
    main_inputs_fwd = main_inputs_fwd$ENV_FWD$dt_fwds
    # saveRDS(main_inputs_fwd, 'main_inputs_fwd.rds')
    
    Sys.sleep(5)
    ### gas for apply_shape
    main_inputs_fwd_gas = prepare_fwd(
        fwd_pwr_code = NULL,
        fwd_gas_code = 'TTF',
        start_date = start_horizon,
        end_date = end_horizon,
        model_type = 'GAS',
        forecast_source = 'FWD',
        archive = 'NO',
        manual_pwr = NULL,
        manual_gas = NULL,
        reuters_key = Sys.getenv('REUTERS_KEY')
    )
    main_inputs_fwd_gas = main_inputs_fwd_gas$ENV_FWD$dt_fwds
    # saveRDS(main_inputs_fwd_gas, 'main_inputs_fwd_gas.rds')
    
    Sys.sleep(5)
    basketpwr_inputs_fwd = lapply(eikondata::pwr_products_full[countries %in% commodity_basket]$countries, function(x) {
        dts = prepare_fwd(
            fwd_pwr_code = x,
            fwd_gas_code = NULL,
            start_date = start_horizon,
            end_date = end_horizon,
            model_type = 'PWR',
            forecast_source = 'FWD',
            archive = 'NO',
            manual_pwr = NULL,
            manual_gas = NULL,
            reuters_key = Sys.getenv('REUTERS_KEY')
        )
        return(dts)
    })
    
    basketpwr_inputs_fwd = rbindlist(lapply(basketpwr_inputs_fwd, function(x) x$ENV_FWD$dt_fwds))
    # saveRDS(basketpwr_inputs_fwd, 'basketpwr_inputs_fwd.rds')
    
    Sys.sleep(5)
    basketgas_inputs_fwd = lapply(eikondata::gas_products_full[products_GAS %in% commodity_basket]$products_GAS, function(x) {
        dts = prepare_fwd(
            fwd_pwr_code = NULL,
            fwd_gas_code = x,
            start_date = start_horizon,
            end_date = end_horizon,
            model_type = 'GAS',
            forecast_source = 'FWD',
            archive = 'NO',
            manual_pwr = NULL,
            manual_gas = NULL,
            reuters_key = Sys.getenv('REUTERS_KEY')
        )
        return(dts)
    })
    
    basketgas_inputs_fwd = rbindlist(lapply(basketgas_inputs_fwd, function(x) x$ENV_FWD$dt_fwds))
    # saveRDS(basketgas_inputs_fwd, 'basketgas_inputs_fwd.rds')
    
    if(any(commodity_basket %in% 'C02')) {
        vec_co2 = paste0(eikondata::CO2_products_full$products_CO2_code, paste0('Z', 0:9))
        dt_co2 = lapply(vec_co2, function(x) {
            tryCatch({
                print(x)
                DT = eikondata::get_rics_f(
                    rics = x, 
                    from_date  = paste0(Sys.Date()-10),
                    to_date  = paste0(Sys.Date())
                )
                setDT(DT)
            }, error = function(e) {
                message(sprintf("Failed to retrieve data for RIC: %s - %s", x, e$message))
                return(NULL)
            })
        })
        dt_co2 = rbindlist(dt_co2)
        colnames(dt_co2) = c('date', 'RIC', 'value', 'volume')
        dt_co2[, date := as.Date(date)]
        dt_co2[, volume := NULL]
        dt_co2 = dt_co2[dt_co2[, .I[date == max(date)], by = RIC]$V1]
        dt_co2 = dt_co2[!is.na(date)]
        dt_co2 = dt_co2[, .(RIC, yymm = date, value)]
        dt_co2[, yymm := as.Date(sprintf("%d-01-01",
                                         fifelse(substr(RIC, 6, 6) == "0", 
                                                 2030, 
                                                 2020 + as.integer(substr(RIC, 6, 6)))))]
        dt_co2[, RIC := 'C02']
        dt_co2_expanded = dt_co2[, {
            yr = year(yymm)
            months = seq.Date(as.Date(sprintf("%d-01-01", yr)),
                              as.Date(sprintf("%d-12-01", yr)),
                              by = "1 month")
            .(RIC = RIC[1], yymm2 = months, value = value[1])
        }, by = yymm]
        dt_co2_expanded = dt_co2_expanded[, .(yymm = yymm2, RIC, value)]
    }
    
    # saveRDS(dt_co2_expanded, 'dt_co2_expanded.rds')
    if(any(commodity_basket %in% 'C02')) {
        list_fwds = list(main_inputs_fwd, main_inputs_fwd_gas, basketpwr_inputs_fwd, basketgas_inputs_fwd, dt_co2_expanded)
        names(list_fwds) = c('main_inputs_fwd', 'main_inputs_fwd_gas', 'basketpwr_inputs_fwd', 'basketgas_inputs_fwd', 'dt_co2_expanded')
    } else {
        list_fwds = list(main_inputs_fwd, main_inputs_fwd_gas, basketpwr_inputs_fwd, basketgas_inputs_fwd)
        names(list_fwds) = c('main_inputs_fwd', 'main_inputs_fwd_gas', 'basketpwr_inputs_fwd', 'basketgas_inputs_fwd')
    }
    
    ## SPOTS
    is_eikon_pwr = eikondata::pwr_mapped_codes[countries == commodity_main]$eikon
    is_eikon_gas = eikondata::gas_mapped_codes[products %in% commodity_basket]$eikon
    
    
    pwr_codes = eikondata::pwr_products_full[countries %in% commodity_main]$spot_PWR_code
    
    if (is_eikon_pwr == 'NO') {
        file_path = file.path(file.path('HPFC', 'last', 'history'), 'backup_spot_pwr.xlsx')
        print(file_path)
        sheet_names = openxlsx::getSheetNames(file_path)
        print(sheet_names)
        df = openxlsx::read.xlsx(file_path, sheet = pwr_codes, detectDates = TRUE)
        history_main = data.table::as.data.table(df)
    } else {
        history_main = eikondata::dt_spot_pwr[RIC == pwr_codes]
    }
    
    if(is_eikon_pwr == 'YES' & as.character(end_train) >= '2025-01-01') {
        DT_NEW = eikondata::retrieve_spot(
            ric = pwr_codes,
            from_date = '2025-01-01',
            to_date = end_train,
            type = 'PWR')
        
        history_main = 
            rbind(
                history_main,
                DT_NEW,
                use.names=TRUE
            )
    }
    
    history_main = history_main[date >= start_train & date <= end_train]
    
    gas_codes = eikondata::gas_products_full[products_GAS %in% 'TTF']$spot_GAS_code
    history_ttf = eikondata::dt_spot_gas[RIC == gas_codes]
    
    if(as.character(end_train) >= '2025-01-01') {
        DT_NEW = eikondata::retrieve_spot(
            ric = gas_codes,
            from_date = '2025-01-01',
            to_date = end_train,
            type = 'GAS')
        
        history_ttf = 
            rbind(
                history_ttf,
                DT_NEW,
                use.names=TRUE
            )
    }
    
    history_ttf = history_ttf[date >= start_train & date <= end_train]
    
    history_basket_pwr = lapply(eikondata::pwr_products_full[countries %in% commodity_basket]$countries, function(x) {
        
        pwr_codes = eikondata::pwr_products_full[countries %in% x]$spot_PWR_code
        is_eikon_pwr = eikondata::pwr_mapped_codes[countries == x]$eikon
        
        if (is_eikon_pwr == 'NO') {
            file_path = file.path(file.path('HPFC', 'last', 'history'), 'backup_spot_pwr.xlsx')
            print(file_path)
            sheet_names = openxlsx::getSheetNames(file_path)
            print(sheet_names)
            df = openxlsx::read.xlsx(file_path, sheet = x, detectDates = TRUE)
            history_main = data.table::as.data.table(df)
        } else {
            history_main = eikondata::dt_spot_pwr[RIC == pwr_codes]
        }
        
        if(is_eikon_pwr == 'YES' & as.character(end_train) >= '2025-01-01') {
            DT_NEW = eikondata::retrieve_spot(
                ric = pwr_codes,
                from_date = '2025-01-01',
                to_date = end_train,
                type = 'PWR')
            
            history_main = 
                rbind(
                    history_main,
                    DT_NEW,
                    use.names=TRUE
                )
        }
        
        history_main
        
    })
    
    history_basket_pwr = rbindlist(history_basket_pwr)
    history_basket_pwr = history_basket_pwr[date >= start_train & date <= end_train]
    
    
    history_basket_gas = lapply(eikondata::gas_products_full[products_GAS %in% commodity_basket]$products_GAS, function(x) {
        is_eikon_gas = eikondata::gas_mapped_codes[products %in% x]$eikon
        gas_codes = eikondata::gas_products_full[products_GAS %in% x]$spot_GAS_code
        
        if (is_eikon_gas == 'NO') {
            file_path = file.path(file.path('HPFC', 'last', 'history'), 'backup_spot_gas.xlsx')
            print(file_path)
            sheet_names = openxlsx::getSheetNames(file_path)
            print(sheet_names)
            df = openxlsx::read.xlsx(file_path, sheet = x, detectDates = TRUE)
            history_basket_gas = data.table::as.data.table(df)
        } else {
            history_basket_gas = eikondata::dt_spot_gas[RIC == gas_codes]
        }
        
        if(is_eikon_gas == 'YES' & as.character(end_train) >= '2025-01-01') {
            DT_NEW = eikondata::retrieve_spot(
                ric = gas_codes,
                from_date = '2025-01-01',
                to_date = end_train,
                type = 'GAS')
            
            history_basket_gas = 
                rbind(
                    history_basket_gas,
                    DT_NEW,
                    use.names=TRUE
                )
        }
        
        history_basket_gas
    })
    history_basket_gas = rbindlist(history_basket_gas)
    history_basket_gas = history_basket_gas[date >= start_train & date <= end_train]
    
    
    list_history = list(history_main, history_ttf, history_basket_pwr, history_basket_gas)
    names(list_history) = c('history_main', 'history_ttf', 'history_basket_pwr', 'history_basket_gas')
    
    list_data = list(list_fwds, list_history)
    names(list_data) = c('list_fwds', 'list_history')
    
    return(list_data)
    
}

#' Forward Curve Estimation and Basket Construction Pipeline
#'
#' This function constructs arbitrage-free forward curves for power, gas, and potentially CO2, using historical spot prices and forecasts.
#' It also estimates a synthetic basket based on a GLM model, combining historical and forecast data for each commodity.
#'
#' The pipeline includes the following steps:
#' 1. Retrieve historical spot prices for the main commodity and its basket components (power, gas, CO2).
#' 2. Generate continuation data and clean it for further use.
#' 3. Estimate a weighted basket using GLM coefficients.
#' 4. Visualize historical and weighted basket data.
#' 5. Retrieve and process forward price data for the main commodity and its basket components.
#' 6. Apply arbitrage-free adjustments to the forward prices for power, gas, and CO2 (if applicable).
#'
#' @param commodity_main A character string specifying the main commodity (e.g., power or gas).
#' @param coef_glm A table with the commodoties and coefficientes and weights form the basket.
#' @param start_train A Date or character string representing the start date of the training period (for historical data).
#' @param end_train A Date or character string representing the end date of the training period.
#' @param start_horizon A Date or character string representing the start date of the forecast horizon.
#' @param end_horizon A Date or character string representing the end date of the forecast horizon.
#'
#' @return A data.table object containing the combined arbitrage-free forward curves for the main commodity and basket.
#'         This includes a synthetic basket forward curve based on weighted power and gas forwards, as well as a 
#'         potential CO2 curve if relevant.
#' @import eikondata
#' @import data.table
#' @export

fwd_pipeline = function(commodity_main, coef_glm, list_data, start_train, end_train, start_horizon, end_horizon) {
    
    commodity_basket = unique(coef_glm$COMMODITY)
    
    ## Spot history ---------------------
    eikondata::set_proxy_port(9000L)
    eikondata::set_app_id(Sys.getenv('REUTERS_KEY'))
    
    ## Get History ------------------------------------------------------
    
    list_history = list_data$list_history
    list_fwds = list_data$list_fwds
    
    ## PREPARE ARB FREE CURVES
    history_main = list_history$history_main
    history_ttf = list_history$history_ttf
    history_basket_pwr = list_history$history_basket_pwr
    history_basket_gas = list_history$history_basket_gas
    
    main_inputs_fwd = list_fwds$main_inputs_fwd
    main_inputs_fwd_gas = list_fwds$main_inputs_fwd_gas
    basketpwr_inputs_fwd = list_fwds$basketpwr_inputs_fwd
    basketgas_inputs_fwd = list_fwds$basketgas_inputs_fwd
    
    
    fwd_calendar = eikondata::calendar_holidays
    fwd_calendar[, `:=` (year = as.character(data.table::year(date)), quarter = as.character(data.table::quarter(date)), month = as.character(data.table::month(date)))]
    
    # PREPARE ARB FREE FWD CURVE - MAIN
    # gas for apply_shape
    dt_fwd_gas = eikondata::prep_fwd_curve(DT = main_inputs_fwd_gas,
                                           list_rics = eikondata::gas_products_full[products_GAS %in% commodity_basket]$products_GAS_code,
                                           type = 'GAS',
                                           start_date = start_horizon,
                                           end_date = end_horizon, 
                                           calendar_sim = fwd_calendar)
    dt_gas_fwds = dt_fwd_gas[, .(year, quarter, month, forward_cal_BL_gas, forward_quarter_BL_gas, forward_month_BL_gas)]
    dt_gas_fwds = dt_gas_fwds[, lapply(.SD, as.numeric)]
    
    
    free_fwd_gas = HPFC::arbitrage_free_gas(dt_gas_fwds, DT_history = history_ttf, colnames(dt_gas_fwds))
    dt_gas_freearb_fwds_main = free_fwd_gas[, .(sim = 'FWD', yymm = as.Date(paste(year, month, '01', sep = '-')), value = BL_quotes_gas)]

    # MAIN
    dt_fwd_pwr = eikondata::prep_fwd_curve(DT = main_inputs_fwd,
                                           list_rics = eikondata::pwr_products_full[countries %in% commodity_main]$products_PWR_code,
                                           type = 'PWR',
                                           start_date = start_horizon,
                                           end_date = end_horizon,
                                           calendar_sim = fwd_calendar)


    dt_pwr_fwds = dt_fwd_pwr[, .(year, quarter, month, forward_cal_BL_pwr, forward_quarter_BL_pwr,
                                 forward_month_BL_pwr, forward_cal_PL_pwr, forward_quarter_PL_pwr, forward_month_PL_pwr)]
    dt_pwr_fwds = dt_pwr_fwds[, lapply(.SD, as.numeric)]

    history_main_fa = history_main[, .(date, hour, value, RIC)]
    history_main_fa = history_main_fa[, .(date, hour, value)]
    history_main_fa = HPFC::break_detection_ddhh(history_main_fa)
    history_main_fa = HPFC::filter_outlier_dd_pwr(history_main_fa)
    free_fwd_pwr = HPFC::arbitrage_free_power(dt_pwr_fwds, DT_history = history_main_fa, colnames(dt_pwr_fwds))
    dt_pwr_freearb_fwds_main = free_fwd_pwr[, .(sim = 'FWD', yymm = as.Date(paste(year, month, '01', sep = '-')), value = BL_quotes)]


    ## PREPARE ARB FREE GAS

    # PREPARE ARB FREE FWD CURVE
    # gas for apply_shape
    vec_gas = eikondata::gas_products_full[products_GAS %in% commodity_basket]$products_GAS_code
    list_dt_gas_freearb_fwds = lapply(vec_gas, function(gas_code, history, start_date, end_date, calendar_sim) {
        dt_gas_basket = basketgas_inputs_fwd[substr(RIC, 1, 3) %in% substr(gas_code, 1, 3)]

        dt_fwd_gas = eikondata::prep_fwd_curve(
            DT = dt_gas_basket,
            list_rics = gas_code,
            type = 'GAS',
            start_date = start_date,
            end_date = end_date,
            calendar_sim = calendar_sim
        )

        dt_gas_fwds = dt_fwd_gas[, .(year, quarter, month, forward_cal_BL_gas, forward_quarter_BL_gas, forward_month_BL_gas)]
        dt_gas_fwds = dt_gas_fwds[, lapply(.SD, as.numeric)]

        history = history_basket_gas[RIC %in% eikondata::gas_products_full[products_GAS %in% gas_code]$spot_GAS_code]

        free_fwd_gas = HPFC::arbitrage_free_gas(
            dt_gas_fwds,
            DT_history = history,
            colnames(dt_gas_fwds)
        )

        dt_gas_freearb_fwds = free_fwd_gas[, .(products_GAS_code = gas_code, yymm = as.Date(paste(year, month, '01', sep = '-')), value = BL_quotes_gas)]

        return(dt_gas_freearb_fwds)
    },  history = history_basket_gas,
    start_date = start_horizon,
    end_date = end_horizon,
    calendar_sim = fwd_calendar)

    dt_gas_freearb_fwds = rbindlist(list_dt_gas_freearb_fwds)

    ## PREPARE ARB FREE PWR

    # PREPARE ARB FREE FWD CURVE
    # gas for apply_shape
    vec_pwr = eikondata::pwr_products_full[countries %in% commodity_basket]$products_PWR_code
    list_dt_pwr_freearb_fwds = lapply(vec_pwr, function(pwr_code, history, start_date, end_date, calendar_sim) {
        dt_pwr_basket = basketpwr_inputs_fwd[substr(RIC, 1, 2) == pwr_code]
        dt_pwr_basket = dt_pwr_basket[date >= start_horizon]
        dt_fwd_pwr = eikondata::prep_fwd_curve(
            DT = dt_pwr_basket,
            list_rics = pwr_code,
            type = 'PWR',
            start_date = start_date,
            end_date = end_date,
            calendar_sim = calendar_sim
        )

        dt_pwr_fwds = dt_fwd_pwr[, .(year, quarter, month, forward_cal_BL_pwr, forward_quarter_BL_pwr,
                                     forward_month_BL_pwr, forward_cal_PL_pwr, forward_quarter_PL_pwr, forward_month_PL_pwr)]
        dt_pwr_fwds = dt_pwr_fwds[, lapply(.SD, as.numeric)]

        history = history[RIC == eikondata::pwr_products_full[products_PWR_code %in% pwr_code]$spot_PWR_code]

        history_main_fa = history[, .(date, hour, value, RIC)]
        history_main_fa = history_main_fa[, .(date, hour, value)]
        history_main_fa = HPFC::break_detection_ddhh(history_main_fa)
        history_main_fa = HPFC::filter_outlier_dd_pwr(history_main_fa)
        free_fwd_pwr = HPFC::arbitrage_free_power(dt_pwr_fwds, DT_history = history_main_fa, colnames(dt_pwr_fwds))
        dt_pwr_freearb_fwds_main = free_fwd_pwr[, .(products_PWR_code = pwr_code, yymm = as.Date(paste(year, month, '01', sep = '-')), value = BL_quotes)]

        return(dt_pwr_freearb_fwds_main)
    },  history = history_basket_pwr,
    start_date = start_horizon,
    end_date = end_horizon,
    calendar_sim = fwd_calendar
    )

    dt_pwr_freearb_fwds = rbindlist(list_dt_pwr_freearb_fwds)


    ## PREPARE FWD BASKET SYNTH
    dt_pwr_freearb_fwds = merge(eikondata::pwr_products_full[countries %in% commodity_basket], dt_pwr_freearb_fwds, by = 'products_PWR_code')
    dt_gas_freearb_fwds = merge(eikondata::gas_products_full[products_GAS %in% commodity_basket], dt_gas_freearb_fwds, by = 'products_GAS_code')

    dt_pwr_freearb_fwds = dt_pwr_freearb_fwds[, .(RIC = countries, yymm, value)]
    dt_gas_freearb_fwds = dt_gas_freearb_fwds[, .(RIC = products_GAS, yymm, value)]

    if(any(commodity_basket %in% 'C02')) {
        dt_basket = rbindlist(list(dt_pwr_freearb_fwds, dt_gas_freearb_fwds, list_fwds$dt_co2_expanded), use.names = TRUE)
    } else {
        dt_basket = rbindlist(list(dt_pwr_freearb_fwds, dt_gas_freearb_fwds), use.names = TRUE)

    }
    
    dt_basket[, COMMODITY := RIC]
    dt_basket[, RIC := NULL]
    coef_glm[, RIC := NULL]
    dt_basket = merge(coef_glm, dt_basket, by = 'COMMODITY')
    dt_basket[, value_new := coeff * value]

    dt_basket = dt_basket[, .(sim = 'FWD', value = sum(value_new, na.rm = TRUE)), by = 'yymm']
    dt_basket = dt_basket[, .(sim, yymm, value)]


    ## APPLY SHAPE
    ## LOAD MODELS
    ENV_MODELS_GAS = list()
    ENV_MODELS_PWR = list()

    last_path = file.path('HPFC', 'last', 'models', commodity_main)
    # last_path = file.path('HPFC', 'last', 'models', commodity_main)
    ENV_MODELS_GAS$dt_lt_param_gasdep = readRDS(file.path(last_path, paste0('model_gas_lt.rds')))
    ENV_MODELS_PWR$dt_lt_param_pwr = readRDS(file.path(last_path, paste0('model_pwr_lt.rds')))
    ENV_MODELS_PWR$lst_hr_param_pwr = readRDS(file.path(last_path, paste0('model_pwr_st.rds')))


    # outputs - DT_FWD_main, DT_FWD_basket
    # APPLY SHAPE:
    DT_FWD_main = apply_shape(
        country = commodity_main,
        name = 'FWD',
        start_date = start_horizon,
        end_date = end_horizon,
        dt_fwd_pwr = dt_pwr_freearb_fwds_main,
        dt_spot_pwr = history_main,
        dt_fwd_gas = dt_gas_freearb_fwds_main,
        dt_spot_gas = history_ttf,
        model_gas = ENV_MODELS_GAS,
        model_pwr = ENV_MODELS_PWR
    )

    DT_FWD_basket = apply_shape(
        country = commodity_main,
        name = 'FWD',
        start_date = start_horizon,
        end_date = end_horizon,
        dt_fwd_pwr = dt_basket,
        dt_spot_pwr = history_main,
        dt_fwd_gas = dt_gas_freearb_fwds_main,
        dt_spot_gas = history_ttf,
        model_gas = ENV_MODELS_GAS,
        model_pwr = ENV_MODELS_PWR
    )

    output = list(DT_FWD_main, DT_FWD_basket)
    names(output) =  c('MAIN', 'PROXY')
    saveRDS(output, 'output.rds')
    
    return(output)
    
}