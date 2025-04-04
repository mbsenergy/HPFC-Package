
# SETUP ------------------------------------------------------------------------------------------------- 

library(shiny)
library(shinyjs)
library(bslib)        # for bslib theme and components
library(echarts4r)     # for interactive charts
library(reactable)     # for interactive tables
library(shinycssloaders) # for loading spinner
library(magrittr)
library(react)
# library(HPFC)
devtools::load_all()


hpfc_theme =
    bs_theme(
        version = 5,
        bootswatch = 'zephyr',
        primary = '#287bb5',
        secondary = '#dee2e6',
        success = '#2fb380',
        info = 'steelblue',
        warning = '#f4bd61',
        danger = '#d08770',
        base_font = font_google(family = "Inter"),
        heading_font = font_google(family = "Inter"),
        font_scale = 0.9
    )


# INPUTS ------------------------------------------------------------------------------------------------- 

## Training ===========================================================================================

vec_pwr_products =        HPFC::spot_PWR_products_full$countries
names(vec_pwr_products) = HPFC::spot_PWR_products_full$countries
vec_gas_products =        HPFC::spot_GAS_products_full$products_GAS
names(vec_gas_products) = HPFC::spot_GAS_products_full$products_GAS


### TRAINING PERIOD --------------------------------------------------------
select_history_period =
    dateRangeInput(
        inputId = "in_select_history",
        label = span("Select history Interval:", style = 'font-weight: bold;'),
        start  = "2016-01-01",
        end    = "2024-12-31",
        min    = "2016-01-01",
        max    = Sys.Date(),
        format = "yyyy/mm/dd",
        separator = " - ",
        width = '100%'
    )


### SELECT PRODUCTS --------------------------------------------------------
select_PWR_product =
    selectInput(
        inputId = "in_select_PWR_indicator",
        label = span("Power:", style = 'font-weight: bold;'),
        multiple = FALSE,
        width = '100%',
        choices = vec_pwr_products,
        selected = 'Greece'
    )

select_GAS_product =
    selectInput(
        inputId = "in_select_GAS_indicator",
        label = span("Gas:", style = 'font-weight: bold;'),
        multiple = FALSE,
        width = '100%',
        choices = vec_gas_products,
        selected = 'TTF'
    )

#### BUTTON TO EXECUTE TRAINING --------------------------------
product_train =
    actionButton(
        inputId = 'act_indicator_train',
        label = 'Train model',
        icon = shiny::icon('backward'),
        width = '100%',
        class = "btn-danger"
    )

#### DATA SOURCE --------------------------------
select_source =
    radioButtons(
        inputId = "in_source",
        label = span("Select data source:", style = 'font-weight: bold;'),
        choices = c("Reuters" = "0df86b690b2c4ae2bf245680dbbfcc86bb041dc9",
                    "Excel" = 'LOCAL'),
        inline = FALSE
    )

### BUTTONS EXECUTE DOWNLOAD -----------------------
train_pwr_download =
    downloadButton(
        outputId = 'act_train_pwr_download',
        label = 'Power Download',
        icon = shiny::icon('download'),
        style = "width:50%;",
        class = "btn-secondary"
    )

train_gas_download =
    downloadButton(
        outputId = 'act_train_gas_download',
        label = 'Gas Download',
        icon = shiny::icon('download'),
        style = "width:50%;",
        class = "btn-secondary"
    )



## Forecast ====================================================================================

### FORECASTING PERIOD --------------------------------------------------------
select_horizon_period =
    dateRangeInput(
        inputId = "in_select_horizon",
        label = span("Select forecast horizon Interval:", style = 'font-weight: bold;'),
        start  = '2024-01-01',
        end    = '2024-12-31', 
        min    = '2017-01-01',
        max    = '2030-12-31',
        format = "yyyy/mm/dd",
        separator = " - ",
        width = '100%'
    )

### SELECT PRODUCTS --------------------------------------------------------

select_PWR_product_train =
    selectInput(
        inputId = "in_select_PWR_indicator_train",
        label = span("Power", style = 'font-weight: bold;'),
        multiple = FALSE,
        width = '100%',
        choices = vec_pwr_products,
        selected = 'Greece'
    )


select_GAS_product_train =
    selectInput(
        inputId = "in_select_GAS_indicator_train",
        label = span("Gas:", style = 'font-weight: bold;'),
        multiple = FALSE,
        width = '100%',
        choices = vec_gas_products,
        selected = 'TTF'
    )


#### BUTTON TO EXECUTE FORECAST --------------------------------
product_forecast =
    actionButton(
        inputId = 'act_indicator_forecast',
        label = 'Forecast',
        icon = shiny::icon('eye'),
        width = '100%',
        class = "btn-warning"
    )


#### DATA SOURCE --------------------------------
select_source_forecast =
    radioButtons(
        inputId = "in_source_forecast",
        label = span("Select data source:", style = 'font-weight: bold;'),
        choices = c("Reuters" = "0df86b690b2c4ae2bf245680dbbfcc86bb041dc9",
                    "Excel" = 'LOCAL'),
        inline = FALSE
    )


### BUTTONS EXECUTE DOWNLOAD -----------------------
fwd_pwr_download =
    downloadButton(
        outputId = 'act_forecast_pwr_download',
        label = ' Power',
        icon = shiny::icon('download'),
        style = "width:50%;",
        class = "btn-secondary"
    )

fwd_gas_download =
    downloadButton(
        outputId = 'act_forecast_gas_download',
        label = ' Gas',
        icon = shiny::icon('download'),
        style = "width:50%;",
        class = "btn-secondary"
    )



### PLOT SELECTORS -----------------------
plot_forecast_selector_gas =
    selectInput(
        inputId = "in_plot_forecast_selector_gas",
        label = NULL,
        multiple = FALSE,
        width = '100%',
        choices = c('TTF' = 'TFMB')
    )

plot_forecast_selector_pwr =
    selectInput(
        inputId = "in_plot_forecast_selector_pwr",
        label = NULL,
        multiple = FALSE,
        width = '100%',
        choices = c('TTF' = 'TFMB')
    )



# UI ------------------------------------------------------------------------------------------------- 

ui = page_navbar(
    
    # Use bslib for custom themes
    theme = hpfc_theme,
    
    # Title Panel of the app
    title = "HPFC App",
    
    bg = '#287bb5',
    
    # Tabs in the NavbarPage (Train and Forecast)
    nav_panel(title = 'TRAIN',
        layout_sidebar(
                   sidebar = sidebar(
                       width = 400, padding = '40',
                       title = 'Training',
                             select_history_period,
                             select_PWR_product_train,
                             select_GAS_product_train,
                             br(),
                             product_train,
                             br(),
                             select_source,
                             uiOutput("reactive_select_source_file"),
                             hr(),
                             fluidRow(train_pwr_download, train_gas_download),
                             br()
                        ),
                 
                 # Main Panel for the training
                        navset_card_pill(
                            full_screen = TRUE,
                            nav_panel('Power',
                                layout_sidebar(
                                    sidebar = sidebar(reactableOutput('forecast_params_table_recap_pwr'), position = 'right', open = FALSE, width = '450px'),
                                    fluidRow(
                                    echarts4rOutput(outputId = 'pwr_history_plot', height = '400px') %>% withSpinner(color = "#d08770"),
                                    hr(), br(),
                                    reactableOutput(outputId = 'pwr_history_table') %>% withSpinner(color = "#d08770")
                                    )
                                )
                            ),
                            
                            nav_panel('Gas',
                              layout_sidebar(
                                  sidebar = sidebar(reactableOutput('forecast_params_table_recap_gas'), position = 'right', open = FALSE, width = '450px'),
                                  fluidRow(
                                    echarts4rOutput(outputId = 'gas_history_plot', height = '400px') %>% withSpinner(color = "#d08770"),
                                    hr(), br(),
                                    reactableOutput(outputId = 'gas_history_table') %>% withSpinner(color = "#d08770")
                                )
                              )
                            )
                        )
        )
    ),
    
    nav_panel(title = 'FORECAST',
        layout_sidebar(
                   sidebar = sidebar(
                       width = 400, padding = '40',
                       title = 'Forecasting',
                             select_horizon_period,
                             select_PWR_product,
                             select_GAS_product,
                             br(),
                             product_forecast,
                             br(),
                             select_source_forecast,
                             uiOutput("reactive_select_source_file_forecast"),
                             hr(),
                             fluidRow(fwd_gas_download, fwd_pwr_download),
                             br()
                        ),
                 
                 # Main Panel for the forecast
                        navset_card_pill(
                            full_screen = TRUE,
                            height = '845px',
                            nav_panel('Power', class = 'p-1',
                                fluidRow(
                                    h5('Historical Power prices'),
                                    echarts4rOutput(outputId = 'pwr_historysaved_plot', height = '300px') %>% withSpinner(color = "#d08770")
                                ),
                                hr(), br(),
                                fluidRow(
                                    column(width = 4, h5('Forecast Power prices')),
                                    column(width = 4, plot_forecast_selector_pwr),
                                    column(width = 4, p(''))
                                ),
                                fluidRow(
                                    echarts4rOutput(outputId = 'pwr_forecast_plot', height = '300px') %>% withSpinner(color = "#d08770")
                                )
                            ),
                            
                            nav_panel('Gas', class = 'p-1',
                                fluidRow(
                                    h5('Historical Gas prices'),
                                    echarts4rOutput(outputId = 'gas_historysaved_plot', height = '300px') %>% withSpinner(color = "#d08770")
                                ),
                                hr(), br(),
                                fluidRow(
                                    column(width = 4, h5('Forecast Gas prices')),
                                    column(width = 4, plot_forecast_selector_gas),
                                    column(width = 4, p(''))
                                ),
                                fluidRow(
                                    echarts4rOutput(outputId = 'gas_forecast_plot', height = '300px') %>% withSpinner(color = "#d08770")
                                )
                            )
                        )
        )
             ),
    
    nav_panel(title = "BACKTEST",
             fluidRow('PLACEHOLDER')
             ),
    
    nav_panel(title = "RECAP",
             fluidRow(
                 column(12,
                        h3("Input Recap"),
                        reactableOutput("input_recap_table")
                 )
             )
    )
)




# SERVER  ------------------------------------------------------------------------------------------------- 
server = function(input, output, session) {
    
    # Reactive input for select source in training period
    output$reactive_select_source_file <- renderUI({
        req(input$in_source)
        if(input$in_source == "Excel") {
            fileInput("file", "Upload Excel File", accept = c(".xlsx"))
        }
    })
    
    # Reactive input for select source in forecast period
    output$reactive_select_source_file_forecast <- renderUI({
        req(input$in_source_forecast)
        if(input$in_source_forecast == "Excel") {
            fileInput("file_forecast", "Upload Excel File", accept = c(".xlsx"))
        }
    })
    
    # Reactive input recap data -----------------
    recap_data = reactive({
        data.frame(
            Input = c("History Period", "Power Products (Training)", "Gas Products (Training)", "Data Source (Training)",
                      "Forecast Horizon Period",  "Power Products (Forecast)", "Gas Products (Forecast)", "Data Source (Forecast)"),
            Value = c(paste(input$in_select_history[1], "to", input$in_select_history[2]),
                      paste(input$in_select_PWR_indicator_train, collapse = ", "),
                      paste(input$in_select_GAS_indicator_train, collapse = ", "),
                      input$in_source,
                      paste(input$in_select_horizon[1], "to", input$in_select_horizon[2]),
                      paste(input$in_select_PWR_indicator, collapse = ", "),
                      paste(input$in_select_GAS_indicator, collapse = ", "),
                      input$in_source_forecast)
        )
    })
    
    # Render the recap table
    output$input_recap_table = renderReactable({
        reactable(recap_data(), columns = list(
            Value = colDef(width = 200)
        ))
    })
    
    
    # TRAIN - PWR ------------------------------------------
    
    ## Inputs -----------------------
    params_input_pwr = reactiveVal(NULL)
    list_inputs_field_pwr = reactiveVal(NULL)
    
    ### Prepare inputs params
    observe({
        params_list = list(
            model_type = 'PWR',
            selected_pwr_code = input$in_select_PWR_indicator_train,
            selected_gas_code = 'TTF',
            dependent_gas_code = 'TTF',
            history_start = input$in_select_history[1],
            history_end = input$in_select_history[2],
            forecast_start = input$in_select_horizon[1],
            forecast_end = input$in_select_horizon[2],
            model_source = 'TRAIN',
            data_source = input$in_source, #0df86b690b2c4ae2bf245680dbbfcc86bb041dc9
            forecast_source = 'FWD',
            sim_name = 'NO',
            archive = 'NO'
        )
        
        params_input_pwr(params_list)
        
    })
    
    ### Exceute load_inputs
    observeEvent(input$act_indicator_train, {
        
        print('')
        print('==================== ++++++++++++++ ====================')
        print('==================== START TRAINING PWR ====================')
        print('==================== ++++++++++++++ ====================')
        print('')
        print('------------- LOAD INPUTS START -------------')
        
        LST_PARAMS = react$params_input_pwr
        list_inputs = HPFC::load_inputs(params = LST_PARAMS)
        
        list_inputs_field_pwr(list_inputs)
        
        print('------------- LOAD INPUTS END ---------------')
        
        })
    
    
    
    
    ## Prepare Curves -----------------------
    prepare_gas_field_pwr = reactiveVal(NULL)
    prepare_pwr_field = reactiveVal(NULL)
    
    observe({
        
        req(react$list_inputs_field_pwr)
        
        print('==================== ++++++++++++++ ====================')
        print('------------- PREPARE START -------------')
        
        list_inputs = react$list_inputs_field_pwr
        ENV_MODELS_GAS = prepare_gas(list_inputs = list_inputs)
        ENV_MODELS_PWR = prepare_pwr(list_inputs = list_inputs)
        
        prepare_gas_field_pwr(ENV_MODELS_GAS)
        prepare_pwr_field(ENV_MODELS_PWR)
        
        print('------------- PREPARE END ---------------')
        
    })
    
    
    ## Train Models -----------------------
    models_gas_field_pwr = reactiveVal(NULL)
    models_pwr_field = reactiveVal(NULL)
    
    observe({
        
        req(react$prepare_gas_field_pwr)
        req(react$prepare_pwr_field)
        
        print('==================== ++++++++++++++ ====================')
        print('------------- TRAIN START -------------')
        
        ENV_MODELS_GAS = react$prepare_gas_field_pwr
        ENV_MODELS_PWR = react$prepare_pwr_field
        
        ENV_MODELS_GAS$dt_lt_param_gasdep = 
            train_lt_gas(
                gas_data = ENV_MODELS_GAS$dt_lt_param_gasdep,
                ric_gas = unique(ENV_MODELS_GAS$dt_gas$RIC)
            )
        
        ENV_MODELS_PWR$dt_lt_param_pwr = 
            train_lt_pwr(
                pwr_data = ENV_MODELS_PWR$dt_lt_param_pwr,
                ric_pwr = unique(ENV_MODELS_PWR$dt_pwr$RIC),
                pwr_holidays = ENV_MODELS_PWR$calendar_holidays_pwr,
                gas_history = ENV_MODELS_PWR$gas_history
            )
        
        ENV_MODELS_PWR$lst_hr_param_pwr = 
            train_st_pwr(
                pwr_data = ENV_MODELS_PWR$dt_hr_param_pwr,
                gas_history = ENV_MODELS_PWR$gas_history
            )
        
        models_gas_field_pwr(ENV_MODELS_GAS)
        models_pwr_field(ENV_MODELS_PWR)
        
        print('------------- TRAIN END ---------------')
        
    })
    
    
    ## Forecast Parameters -----------------------
    forecast_params_field_pwr = reactiveVal(NULL)
    forecast_params_table_pwr = reactiveVal(NULL)
    
    observe({
        
        req(react$models_gas_field_pwr)
        req(react$models_pwr_field)
        
        print('==================== ++++++++++++++ ====================')
        print('------------- FORECAST PARAMS PREP START -------------')
        
        ENV_MODELS_GAS = react$models_gas_field_pwr
        ENV_MODELS_PWR = react$models_pwr_field
        list_inputs = react$list_inputs_field_pwr
        LST_PARAMS = react$params_input_pwr
        
        LST_FOR = list(
            model_lt_gas = copy(ENV_MODELS_GAS$dt_lt_param_gasdep),
            model_lt_pwr = copy(ENV_MODELS_PWR$dt_lt_param_pwr),
            model_st_pwr = copy(ENV_MODELS_PWR$lst_hr_param_pwr),
            dt_fwds = copy(list_inputs$ENV_FWD$dt_fwds),
            saved_history_gas = copy(list_inputs$ENV_SPOT$history_gas),
            saved_history_pwr = copy(list_inputs$ENV_SPOT$history_pwr),
            ric_spot_gas = list_inputs$ENV_SPOT$spot_gas_RIC,
            ric_fwd_gas = unique(LST_PARAMS$dependent_gas_code),
            ric_spot_pwr = list_inputs$ENV_SPOT$spot_pwr_RIC,
            ric_fwd_pwr = unique(LST_PARAMS$selected_pwr_code),
            calendar_forecast = list_inputs$ENV_CODES$calendar_future,
            start_date = LST_PARAMS$forecast_start,
            end_date = LST_PARAMS$forecast_end,
            last_date = list_inputs$ENV_CODES$last_date
        ) 
        
        dt_recap =
            data.table(
                params = names(LST_FOR),
                value = sapply(LST_FOR, function(x) {
                    if (is.data.table(x)) {
                        sprintf("data.table [%d x %d]", nrow(x), ncol(x))
                    } else if (is.list(x)) {
                        sprintf("list [%d elements]", length(x))
                    } else if (is.character(x) || is.numeric(x) || is.logical(x)) {
                        paste0(x, collapse = ", ")
                    } else {
                        paste0(x, collapse = ", ")
                    }
                })
            )        
        
        print('------------- FORECAST PARAMS PREP END -----------------')
        
        forecast_params_field_pwr(LST_FOR)
        forecast_params_table_pwr(dt_recap)
        
        print('')
        print('==================== ++++++++++++++ ====================')
        print('==================== END TRAINING PWR  ====================')
        print('==================== ++++++++++++++ ====================')
        print('')
    })
    
    
    ## Download Power model -----------------------
    object_with_train_data_pwr = reactiveVal(NULL)
    
    observe({
        req(react$models_pwr_field)
        object_with_train_data_pwr(react$models_pwr_field)
    })
    
    output$act_train_pwr_download = downloadHandler(
        filename = function() {
            paste0("train_power_data_", Sys.Date(), ".rds")
        },
        content = function(file) {
            saveRDS(react$object_with_train_data_pwr, file)
        }
    )
    
    
    
    # TRAIN - GAS ------------------------------------------
    
    ## Inputs -----------------------
    params_input_gas = reactiveVal(NULL)
    list_inputs_field_gas = reactiveVal(NULL)
    
    ### Prepare inputs params
    observe({
        params_list = list(
            model_type = 'PWR',
            selected_pwr_code = input$in_select_PWR_indicator_train,
            selected_gas_code = 'TTF',
            dependent_gas_code = 'TTF',
            history_start = input$in_select_history[1],
            history_end = input$in_select_history[2],
            forecast_start = input$in_select_horizon[1],
            forecast_end = input$in_select_horizon[2],
            model_source = 'TRAIN',
            data_source = input$in_source, #0df86b690b2c4ae2bf245680dbbfcc86bb041dc9
            forecast_source = 'FWD',
            sim_name = 'NO',
            archive = 'NO'
        )
        
        params_input_gas(params_list)
        
    })
    
    ### Exceute load_inputs
    observeEvent(input$act_indicator_train, {
        
        print('')
        print('==================== ++++++++++++++ ====================')
        print('==================== START TRAINING GAS ====================')
        print('==================== ++++++++++++++ ====================')
        print('')
        print('------------- LOAD INPUTS START -------------')
        
        LST_PARAMS = react$params_input_gas
        list_inputs = HPFC::load_inputs(params = LST_PARAMS)
        
        list_inputs_field_gas(list_inputs)
        
        print('------------- LOAD INPUTS END ---------------')
        
    })
    
    
    
    
    ## Prepare Curves -----------------------
    prepare_gas_field_gas = reactiveVal(NULL)
    
    observe({
        
        req(react$list_inputs_field_pwr)
        
        print('==================== ++++++++++++++ ====================')
        print('------------- PREPARE START -------------')
        
        list_inputs = react$list_inputs_field_pwr
        ENV_MODELS_GAS = prepare_gas(list_inputs = list_inputs)
        
        prepare_gas_field_gas(ENV_MODELS_GAS)
        
        print('------------- PREPARE END ---------------')
        
    })
    
    
    ## Train Models -----------------------
    models_gas_field_gas = reactiveVal(NULL)
    
    observe({
        
        req(react$prepare_gas_field_gas)
        
        print('==================== ++++++++++++++ ====================')
        print('------------- TRAIN START -------------')
        
        ENV_MODELS_GAS = react$prepare_gas_field_gas
        
        ENV_MODELS_GAS$dt_lt_param_gasdep = 
            train_lt_gas(
                gas_data = ENV_MODELS_GAS$dt_lt_param_gasdep,
                ric_gas = unique(ENV_MODELS_GAS$dt_gas$RIC)
            )
        
        models_gas_field_gas(ENV_MODELS_GAS)
        
        print('------------- TRAIN END ---------------')
        
    })
    
    
    ## Forecast Parameters -----------------------
    forecast_params_field_gas = reactiveVal(NULL)
    forecast_params_table_gas = reactiveVal(NULL)
    
    observe({
        
        req(react$models_gas_field_gas)
        
        print('==================== ++++++++++++++ ====================')
        print('------------- FORECAST PARAMS PREP START -------------')
        
        ENV_MODELS_GAS = react$models_gas_field_gas
        list_inputs = react$list_inputs_field_gas
        LST_PARAMS = react$params_input_gas
        
        LST_FOR = list(
            model_lt_gas = copy(ENV_MODELS_GAS$dt_lt_param_gasdep),
            dt_fwds = copy(list_inputs$ENV_FWD$dt_fwds),
            saved_history_gas = copy(list_inputs$ENV_SPOT$history_gas),
            ric_spot_gas = list_inputs$ENV_SPOT$spot_gas_RIC,
            ric_fwd_gas = unique(LST_PARAMS$dependent_gas_code),
            calendar_forecast = list_inputs$ENV_CODES$calendar_future,
            start_date = LST_PARAMS$forecast_start,
            end_date = LST_PARAMS$forecast_end,
            last_date = list_inputs$ENV_CODES$last_date
        ) 
        
        dt_recap =
            data.table(
                params = names(LST_FOR),
                value = sapply(LST_FOR, function(x) {
                    if (is.data.table(x)) {
                        sprintf("data.table [%d x %d]", nrow(x), ncol(x))
                    } else if (is.list(x)) {
                        sprintf("list [%d elements]", length(x))
                    } else if (is.character(x) || is.numeric(x) || is.logical(x)) {
                        paste0(x, collapse = ", ")
                    } else {
                        paste0(x, collapse = ", ")
                    }
                })
            )        
        
        print('------------- FORECAST PARAMS PREP END -----------------')
        
        forecast_params_field_gas(LST_FOR)
        forecast_params_table_gas(dt_recap)
        
        print('')
        print('==================== ++++++++++++++ ====================')
        print('==================== END TRAINING GAS  ====================')
        print('==================== ++++++++++++++ ====================')
        print('')
    })
    
    
    ## Download Power model -----------------------
    object_with_train_data_pwr = reactiveVal(NULL)
    
    observe({
        req(react$models_pwr_field)
        object_with_train_data_pwr(react$models_pwr_field)
    })
    
    output$act_train_pwr_download = downloadHandler(
        filename = function() {
            paste0("train_power_data_", Sys.Date(), ".rds")
        },
        content = function(file) {
            saveRDS(react$object_with_train_data_pwr, file)
        }
    )
    
    
    object_with_train_data_gas = reactiveVal(NULL)
    
    observe({
        req(react$models_gas_field_gas)
        object_with_train_data_gas(react$models_gas_field_gas)
    })
    
    output$act_train_gas_download = downloadHandler(
        filename = function() {
            paste0("train_gas_data_", Sys.Date(), ".rds")
        },
        content = function(file) {
            saveRDS(react$object_with_train_data_gas, file)
        }
    )    
    
    
    
    

    
    # VISUALIZE ------------------------------------------
    
    ## TRAIN ------------------------------------
    
    ## RECAP FORECAST PARAMS
    output$forecast_params_table_recap_pwr = renderReactable({
        req(react$forecast_params_table_pwr)
        reactable(react$forecast_params_table_pwr,
                  defaultPageSize = 14)
    })
    
    output$forecast_params_table_recap_gas = renderReactable({
        req(react$forecast_params_table_gas)
        reactable(react$forecast_params_table_gas,
                  defaultPageSize = 14)
    })
    
    
    # Outputs for the selected history period (for training)
    output$pwr_history_plot <- renderEcharts4r({
        
        req(react$list_inputs_field_pwr)
        
        list_inputs = react$list_inputs_field_pwr
        DT = copy(list_inputs$ENV_SPOT$history_pwr)
        DT[, datetime := as.POSIXct(paste(date, sprintf("%02d:00:00", hour)), format = "%Y-%m-%d %H:%M:%S", tz = "CET")]
        rics = unique(DT$RIC) 
        setorder(DT, datetime, RIC)
        
        DT %>%
            e_charts(datetime) %>%
            e_line(value, name = rics, symbol = 'none') %>%
            e_title(text = paste("Hourly Prices for", rics)) %>%
            e_x_axis(name = "Datetime") %>%
            e_y_axis(name = "Price") %>%
            e_tooltip(trigger = "axis") %>%
            e_datazoom(type = "slider") %>%
            e_theme("westeros") 

    })
    
    output$pwr_history_table <- renderReactable({
        
        req(react$list_inputs_field_pwr)
        
        list_inputs = react$list_inputs_field_pwr
        DT = copy(list_inputs$ENV_SPOT$history_pwr)
        DT[, datetime := as.POSIXct(paste(date, sprintf("%02d:00:00", hour)), format = "%Y-%m-%d %H:%M:%S", tz = "CET")]
        setorder(DT, datetime, RIC)
        reactable(DT)
    })
    
    
    output$gas_history_plot <- renderEcharts4r({
        
        req(react$list_inputs_field_gas)
        
        list_inputs = react$list_inputs_field_gas
        DT = copy(list_inputs$ENV_SPOT$history_gas)
        rics = unique(DT$RIC) 
        setorder(DT, date, RIC)
        
        DT %>%
            e_charts(date) %>%
            e_line(value, name = rics, symbol = 'none') %>%
            e_title(text = paste("Hourly Prices for", rics)) %>%
            e_x_axis(name = "Date") %>%
            e_y_axis(name = "Price") %>%
            e_tooltip(trigger = "axis") %>%
            e_datazoom(type = "slider") %>%
            e_theme("westeros") 
        
    })
    
    output$gas_history_table <- renderReactable({
        
        req(react$list_inputs_field_gas)
        
        list_inputs = react$list_inputs_field_gas
        DT = copy(list_inputs$ENV_SPOT$history_gas)
        setorder(DT, date, RIC)
        reactable(DT)
    })
    
    
    
    ## FORECAST ------------------------------------
    
    # Forecast plots for Power and Gas using echarts4r
    output$pwr_forecast_plot <- renderEcharts4r({
        e_charts(seq.Date(Sys.Date(), Sys.Date()+30, by="days")) %>%
            e_line(rnorm(30)) %>%
            e_title("Power Price Forecast") %>%
            e_x_axis(name = "Date") %>%
            e_y_axis(name = "Price")
    })
    
    output$gas_forecast_plot <- renderEcharts4r({
        e_charts(seq.Date(Sys.Date(), Sys.Date()+30, by="days")) %>%
            e_line(rnorm(30)) %>%
            e_title("Gas Price Forecast") %>%
            e_x_axis(name = "Date") %>%
            e_y_axis(name = "Price")
    })
    
    # Saved History Plots using echarts4r
    output$pwr_historysaved_plot <- renderEcharts4r({
        e_charts(seq.Date(Sys.Date()-60, Sys.Date(), by="days")) %>%
            e_line(rnorm(60)) %>%
            e_title("Saved Power Price History") %>%
            e_x_axis(name = "Date") %>%
            e_y_axis(name = "Price")
    })
    
    output$gas_historysaved_plot <- renderEcharts4r({
        e_charts(seq.Date(Sys.Date()-60, Sys.Date(), by="days")) %>%
            e_line(rnorm(60)) %>%
            e_title("Saved Gas Price History") %>%
            e_x_axis(name = "Date") %>%
            e_y_axis(name = "Price")
    })
    
    ## END
}


# RUN APP ------------------------------------------------------------------------------------------------- 
shinyApp(ui = ui, server = server)

