######################################################
# James McCammon
# 28 December 2014
# Get Full URLs function
# Version 4
######################################################

# Load libraries and source functions
require(shiny)
require(RCurl)
require(XML)
require(XLConnect)
source("functions.R")

# Define server instance
shinyServer(function(input, output, session) {
  
  # Initialize reactive values 
  values = reactiveValues()
  
  # Function to get file path of uploaded file
  filepath = reactive({
    file = input$datafile
    if(is.null(file)) return()
    return(file$datapath)
  })
  
  # If the uploaded file is Excel create a dropdown menu so the user can select the
  # worksheet with the relevant data.
  observe({
    if(is.null(input$dynamicinput)) {
      if(input$inputformat == 'excel' & !is.null(filepath())) {
        possibleerror = try(values$workbook <- loadWorkbook(filepath()), silent = TRUE)
        if(class(possibleerror) == 'try-error') { seterror('excelloaderror'); return() }
        sheetNames = getSheets(values$workbook)
        output$worksheets = renderUI({
          selectInput(inputId = "dynamicinput", 
                      label = "Select Worksheet",
                      choices = c(sheetNames,'Select' = 'select'),
                      selected = 'select')    
        })
      }
    }
  })
  
  # Create a table with summary data of the file
  output$inputsum = renderTable({
    if(is.null(input$datafile)) return()
    return(input$datafile)
  })
  
  # Create a table with the first 10 rows of the input data
  output$inputdata = renderTable({
    if(is.null(input$datafile) | is.na(input$datacol)) return()
      clearerror()
      # Load the relvant data depending on the file type. If the specified file type doesn't
      # match the loaded file throw an error.
      inputdata = switch(input$inputformat,
                   'excel' = {
                     if(is.null(input$dynamicinput)) return()
                     if(input$inputformat == 'excel' & input$dynamicinput == 'select') return()
                     tryCatch({ readWorksheet(values$workbook, sheet = input$dynamicinput, header = input$dataheader)
                     }, error = function(e) { seterror('excelreaderror'); return() })
                   },
                   'csv' = {
                     tryCatch({ read.csv(file = filepath(), header = input$dataheader, stringsAsFactors = FALSE)
                     }, error = function(e) { seterror('csvloaderror'); return() })
                   })
      # Take the data and get out the first 10 rows. If there is an error it's likely because
      # the specified worksheet or data column has no data. Tell the user this if an error occurs.
      values$inputdata = inputdata
      possibleerror = try(inputdata <- inputdata[[input$datacol]], silent = TRUE)
      if(class(possibleerror) == 'try-error') { seterror('subscripterror'); return() }
      inputdata = as.data.frame(inputdata[1:10])
      names(inputdata)[1] = "short_url_preview" 
      return(inputdata)   
  })
  
  # When the users pushes the "Get Full URLs" button get the URLs by calling the getFWLinks function
  # found in Functions.R. If there is no inpupt data let the user know they forgot to load it.
  observe({
    input$getlinks
    if(input$getlinks == 0) return()
    else {
      updateTabsetPanel(session, inputId = "datatabs", selected = "outputdatatab")
      output$outputdata = renderTable({
      possibleerror = try(values$output <- isolate(getFwLinks(as.data.frame(values$inputdata), input$datacol)), silent = TRUE)
      if(class(possibleerror) == 'try-error') { seterror('nodataerror'); return() }  
      return(as.data.frame(values$output[1:10,]))  
      })  
    }
  })
 
  # When the user selects "Download Full URLs" download them in the specified format.
  # Note the file.rename function is used to handle the temporary filepath created by Shiny.
  output$downloadlinks = downloadHandler(
    filename = function() {
      filename = switch(input$outputformat,
                        'excel' = 'Full_URLs.xlsx',
                        'csv' = 'Full_URLs.csv'
                        )
    },
    content = function(file) {
      if(input$outputformat == 'csv') {
        write.csv(values$output, 'temp.csv', row.names = FALSE)
        file.rename('temp.csv', file)    
      } 
      else {
        outputdata = loadWorkbook('temp.xlsx', create = TRUE)
        createSheet(object = outputdata, name = 'Full_URLs')
        writeWorksheet(outputdata, data = values$output, sheet = 'Full_URLs')
        saveWorkbook(outputdata, 'temp.xlsx')
        file.rename('temp.xlsx', file)    
      }
    }
  )
  
  # Create a function to ouput various error messages
  seterror = function(error) {
    errormessage = switch(error,
                    'excelloaderror' =  'Error: There was an error loading the file. 
                                         Are you sure it is an Excel file? Try changing
                                         your selection to CSV.',
                    'excelreaderror' =  'Error: The workbook loaded, but there was
                                         an error reading the specified worksheet',
                    'csvloaderror'   =  'Error: There was an error loading the file. 
                                         Are you sure it is a csv file?',
                    'fullurlserror'  =  'Error: There was a problem getting the full URLs.
                                         Are you sure you selected the correct data column?',
                    'subscripterror' =  'Error: There does not seem to be any data there.',
                    'nodataerror'    =  'Error: Did you forget to upload data?')
    
    output$errortext = renderUI({
      tags$div(class = "errortext", checked = NA, 
               tags$p(errormessage))
    })
  }
  
  # Define a function to clear error messages.
  clearerror = function() {
    output$errortext = renderUI({
      p('')
    })
  }  
})
