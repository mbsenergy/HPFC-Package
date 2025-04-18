# UI ------------------------------------------------------------------------------------------------- 

ui_app = page_navbar(
    theme = mbs_theme,
    navbar_options = navbar_options(bg = "#001437", underline = FALSE, collapsible = TRUE, theme = 'dark'),
    
    # Title Panel of the app
    title = span("HPFC", style = 'color: white'),
    tags$head(
        tags$script(
            HTML('
          $(document).ready(function() {
            $(".navbar-brand").replaceWith(
              $("<a class = \'navbar-brand\' href = \'#\'></a>")
            );
            var containerHeight = $(".navbar .container-fluid").height() + "px";
            $(".navbar-brand")
              .append(
                "<img id = \'logo\' src=\'logo.png\'" +
                " height = " + containerHeight + ">"  
              );
            });'
            )
        ),
        tags$style(
            HTML('@media (max-width:992px) { .navbar-brand { padding-top: 0; padding-bottom: 0; }}')
        )
    ),
    
    header = tagList(
        useShinyjs(),
        tags$style(".xxxx {margin-left:5px;}"),
        tags$style(".xxxx {margin-left:5px;}"),
        tags$style(HTML('
                        .navbar-nav > li > a {
                              padding: 10px !important;
                              font-color:#d8dee9;
                              letter-spacing: 1px;
                              display: flex;
                              align-items: center;
                            }'
        )
        ),
        tags$style(".topimg {
                            margin-left:5px;
                            margin-right: -15px;
                            margin-top: -19px;
                            margin-bottom: -60px;
                          }"
        )
    ),
    
    # Tabs in the NavbarPage (Train and Forecast)
    
    nav_menu(title = 'HPFC', 
             
             nav_panel(title = 'TRAIN',
                       layout_sidebar(
                           sidebar = sidebar(bg = 'white',
                                             title = h3('Train'),
                                             width = 400,
                                             select_sim_name,
                                             select_history_period,
                                             select_source_train,
                                             uiOutput("select_source_file_train_pwr"),
                                             uiOutput("select_source_file_train_gas"),
                                             accordion(
                                                 accordion_panel(
                                                     title = 'Training Multiple',
                                                     select_PWR_product_mult,
                                                     select_GAS_product_mult,
                                                     product_train_pwr_mult,
                                                     br(),
                                                     product_train_gas_mult
                                                 ),
                                                 accordion_panel(
                                                     title = 'Training Single',
                                                     select_PWR_product,
                                                     select_GAS_product,
                                                     product_train_pwr,
                                                     br(),
                                                     product_train_gas,
                                                     hr(),
                                                     fluidRow(train_pwr_download, train_gas_download)
                                                 )
                                             )
                           ),
                           
                           # Main Panel for the training
                           navset_card_pill(
                               nav_panel('Power Multiple',
                                         fluidRow(
                                             select_pwrplot_mult,
                                             card(
                                                 card_body(fill = TRUE,
                                                           echarts4rOutput(outputId = 'pwr_history_plot_mult') %>% withSpinner(color = "#F2606A")
                                                 )),
                                             card(
                                                 card_body(fill = TRUE,
                                                           datagridOutput(outputId = 'pwr_history_table_mult') %>% withSpinner(color = "#F2606A")
                                                 ))
                                         )
                               ),
                               nav_panel('Gas Multiple',
                                         fluidRow(
                                             select_gasplot_mult,
                                             card(
                                                 card_body(
                                                     echarts4rOutput(outputId = 'gas_history_plot_mult') %>% withSpinner(color = "#F2606A")
                                                 )),
                                             card(
                                                 card_body(
                                                     datagridOutput(outputId = 'gas_history_table_mult') %>% withSpinner(color = "#F2606A")
                                                 ))
                                         )
                               ),
                               nav_panel('Power Single',
                                             fluidRow(
                                                 card(
                                                     card_body(
                                                         echarts4rOutput(outputId = 'pwr_history_plot') %>% withSpinner(color = "#F2606A")
                                                     )),
                                                 card(
                                                     card_body(
                                                         datagridOutput(outputId = 'pwr_history_table') %>% withSpinner(color = "#F2606A")
                                                     ))
                                             )
                               ),
                               
                               nav_panel('Gas Single',
                                             fluidRow(
                                                 card(
                                                     card_body(
                                                         echarts4rOutput(outputId = 'gas_history_plot') %>% withSpinner(color = "#F2606A")
                                                     )),
                                                 card(
                                                     card_body(
                                                         datagridOutput(outputId = 'gas_history_table') %>% withSpinner(color = "#F2606A")
                                                     ))
                                             )
                               )
                           )
                       )
             ),
             
             nav_panel(title = 'FORECAST',
                       layout_sidebar(
                           sidebar = sidebar(bg = 'white',
                                             title = h3('Forecast'),
                                             width = 400, 
                                             select_source_run,
                                             uiOutput("select_source_run"),
                                             select_horizon_horizon,
                                             select_source_forecast,
                                             uiOutput("select_source_file_forecast_pwr"),
                                             uiOutput("select_source_file_forecast_gas"),
                                             accordion(
                                                 accordion_panel(
                                                     title = 'Forecast Multiple',
                                                     select_PWR_product_for_mult,
                                                     select_GAS_product_for_mult,
                                                     product_forecast_pwr_mult,
                                                     br(),
                                                     product_forecast_gas_mult,                                                           
                                                 ),
                                                 accordion_panel(
                                                     title = 'Forecasting Single',
                                                     select_PWR_product_for,
                                                     select_GAS_product_for,
                                                     product_forecast_pwr,
                                                     br(),
                                                     product_forecast_gas,
                                                     hr(),
                                                     fluidRow(fwd_pwr_download, fwd_gas_download)
                                                 )
                                             )
                           ),
                           
                           # Main Panel for the forecast
                           navset_card_pill(
                               nav_panel('Power Multiple',
                                         fluidRow(
                                             select_pwrplot_mult_for,
                                             card(
                                                 card_body(                                             
                                                     echarts4rOutput(outputId = 'pwr_forecast_plot_mult') %>% withSpinner(color = "#C05B8C")
                                                 )),
                                             card(
                                                 card_body(
                                                     datagridOutput(outputId = 'pwr_forecast_table_mult') %>% withSpinner(color = "#C05B8C")
                                                 ))       
                                         )
                               ),
                               
                               nav_panel('Gas Multiple',
                                         fluidRow(
                                             select_gasplot_mult_for,
                                             card(
                                                 card_body(  
                                                     echarts4rOutput(outputId = 'gas_forecast_plot_mult') %>% withSpinner(color = "#C05B8C")
                                                 )),
                                             card(
                                                 card_body(  
                                                     datagridOutput(outputId = 'gas_forecast_table_mult') %>% withSpinner(color = "#C05B8C")
                                                 ))
                                         )
                               ),                               
                               nav_panel('Power Single',
                                         fluidRow(
                                             card(
                                                 card_body(
                                                     echarts4rOutput(outputId = 'pwr_forecast_plot') %>% withSpinner(color = "#C05B8C")
                                                 )),
                                             card(
                                                 card_body(
                                                     datagridOutput(outputId = 'pwr_forecast_table') %>% withSpinner(color = "#C05B8C")
                                                 ))
                                         )
                               ),
                               
                               nav_panel('Gas Single',
                                         fluidRow(
                                             card(
                                                 card_body(
                                                     echarts4rOutput(outputId = 'gas_forecast_plot') %>% withSpinner(color = "#C05B8C")
                                                 )),
                                             card(
                                                 card_body(
                                                     datagridOutput(outputId = 'gas_forecast_table') %>% withSpinner(color = "#C05B8C")
                                                 ))
                                         )
                               )
                           )
                       )
             ),
             
             nav_panel(title = 'LT CURVE',
                       layout_sidebar(
                           sidebar = sidebar(bg = 'white',
                                             title = h3('LT Curve Creation'),
                                             width = 400, padding = '40',
                                             select_lt_train,
                                             span('Get Basket coeff', style = 'font-weight: bold'),
                                             select_main_product,
                                             select_basket,
                                             product_basket_lt,
                                             fluidRow(
                                                 column(3, manual_wg_basket_1),
                                                 column(3, manual_wg_basket_2),
                                                 column(3, manual_wg_basket_3),
                                                 column(3, manual_wg_basket_4)
                                             ),
                                             select_source_weights,
                                             hr(),
                                             span('Curve Preparation', style = 'font-weight: bold'),
                                             select_lt_horizon,
                                             download_fwd_curves,
                                             generate_fwd_curves,
                                             hr(),
                                             upload_scenario,
                                             hr(),
                                             select_cutoff_mkt,
                                             select_cutoff_sce,
                                             select_horizon_total,
                                             product_create_lt,
                                             lt_pwr_download
                                             
                           ),
                           fluidRow(
                               column(width = 12,
                                      card(card_header('Long-Term Final Curve'),
                                           card_body(
                                               echarts4rOutput(outputId = 'pwr_lt_final_plot') %>% withSpinner(color = "#ECB22E")
                                           ),
                                           full_screen = TRUE)
                               )
                           ),
                           fluidRow(
                               column(width = 3,
                                      card(card_header('Coefficients Tables'),
                                           card_body(
                                               datagridOutput(outputId = 'pwr_lt_coeff_table') %>% withSpinner(color = "#ECB22E")
                                           ),
                                           full_screen = TRUE)
                               ),
                               column(width = 3,
                                      card(card_header('Basket & Main Relationship'),
                                           card_body(
                                               echarts4rOutput(outputId = 'pwr_lt_basketcorrelation_plot') %>% withSpinner(color = "#ECB22E")
                                           ),
                                           full_screen = TRUE) 
                               ),
                               column(width = 3,
                                      card(card_header('FWD Curves: Main & Proxy'),
                                           card_body(
                                               echarts4rOutput(outputId = 'pwr_lt_basket_plot') %>% withSpinner(color = "#ECB22E")
                                           ),
                                           full_screen = TRUE)
                               ),
                               column(width = 3,
                                      card(card_header('Scenario Curve'),
                                           card_body(
                                               echarts4rOutput(outputId = 'pwr_lt_scenario_plot') %>% withSpinner(color = "#ECB22E")
                                           ),
                                           full_screen = TRUE)
                               )
                           )
                       )
             ),
             
             nav_panel(title = 'BACKTESTING',
                       fluidRow(column(width = 12,
                                       
                                       card(card_header('Select Power Model to backtest'),
                                            card_body(
                                                fluidRow(
                                                    column(width = 2, select_backtest_source),
                                                    column(width = 2, select_sim_name_backtest),
                                                    column(width = 2, select_PWR_backtest),
                                                    column(width = 2, select_backtest_period),
                                                    column(width = 2, load_backtest),
                                                    column(width = 2, backtest_pwr_download),
                                                )
                                            )),
                                       card(card_header('Select Power Model to backtest'),
                                            card_body(
                                                echarts4rOutput(outputId = 'backtest_overview_plot') %>% withSpinner(color = "#1E328F")
                                            )
                                       )
                       )
                       ),
                       fluidRow(
                           column(width = 4,
                                  card(card_header('Overview'),
                                       card_body(echarts4rOutput(outputId = 'backtest_mean_day_plot', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           ),
                           column(width = 4,
                                  card(card_header('Weighted Error'),
                                       card_body(fluidRow(
                                           column(width = 6,echarts4rOutput(outputId = 'backtest_error_gauge_pv', height = '250px') %>% withSpinner(color = "#1E328F")),
                                           column(width = 6,echarts4rOutput(outputId = 'backtest_error_gauge_lv', height = '250px') %>% withSpinner(color = "#1E328F"))),
                                       )
                                  )
                           ),
                           column(width = 4,
                                  card(card_header('Main Error Metrics'),
                                       card_body(echarts4rOutput(outputId = 'backtest_error_distribution', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           )
                       ),
                       fluidRow(
                           column(width = 3,
                                  card(card_header('Winter'),
                                       card_body(echarts4rOutput(outputId = 'backtest_mean_day_winter', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           ),
                           column(width = 3,
                                  card(card_header('Spring'),
                                       card_body(echarts4rOutput(outputId = 'backtest_mean_day_spring', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           ),
                           column(width = 3,
                                  card(card_header('Summer'),
                                       card_body(echarts4rOutput(outputId = 'backtest_mean_day_summer', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           ),
                           column(width = 3,
                                  card(card_header('Fall'),
                                       card_body(echarts4rOutput(outputId = 'backtest_mean_day_fall', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           )
                       ),
                       fluidRow(
                           column(width = 4,
                                  card(card_header('Table Error Metric: Seasons'),
                                       card_body(datagridOutput(outputId = 'backtest_error_metric_seasons', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           ),
                           column(width = 4,
                                  card(card_header('Table Error Metric: Weekday'),
                                       card_body(datagridOutput(outputId = 'backtest_error_metric_weekday', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           ),
                           column(width = 4,
                                  card(card_header('Table Error Metric: Peak-Off Peak'),
                                       card_body(datagridOutput(outputId = 'backtest_error_metric_peak', height = '250px') %>% withSpinner(color = "#1E328F"))
                                  )
                           )
                       ),
                       fluidRow(
                           column(width = 6,
                                  card(card_header('Error Bias: Seasons'),
                                       card_body(
                                           fluidRow(
                                           column(width = 6, datagridOutput(outputId = 'backtest_error_bias_seasons_a', height = '250px') %>% withSpinner(color = "#1E328F")),
                                           column(width = 6, datagridOutput(outputId = 'backtest_error_bias_seasons_b', height = '250px') %>% withSpinner(color = "#1E328F"))
                                           )
                                       )
                                  )
                           ),
                           column(width = 6,
                                  card(card_header('Error Bias: Peak-Off Peak'),
                                       card_body(
                                           fluidRow(
                                               column(width = 6, datagridOutput(outputId = 'backtest_error_bias_peak_a', height = '250px') %>% withSpinner(color = "#1E328F")),
                                               column(width = 6, datagridOutput(outputId = 'backtest_error_bias_peak_b', height = '250px') %>% withSpinner(color = "#1E328F"))
                                           )
                                       )
                                  )
                           )
                       )                       
             ),
             
             nav_panel(title = 'MONTECARLO',
                       fluidRow(column(width = 12,
                                       
                                       card(card_header('Select Power Model to backtest'),
                                            card_body()
                                       )
                       )
                       )
             )
             
    ),
    
    nav_spacer(),
    
    nav_item(textOutput("reuters_status"))
)


