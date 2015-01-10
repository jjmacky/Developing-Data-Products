require(shiny)

shinyUI(fluidPage(
  titlePanel("Get Full URLs"),
  
  tags$head(
    tags$style(HTML("   
      .errortext {
        font-size: 1em;
        color: red;
        padding-top: 1em;
        padding-bottom: 1em;
      }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      p('In web analytics it is somtimes necessary to transform short URLs into the full
        URL path. For instance, Twitter users often post URLs that are shortned with 
        Bitly, Ow.ly, Tr.im, or other URL shortening web apps. When doing analysis, however,
        you may want to determine the full URL.'), br(),
      
      
      h5('Step 1: Upload the file with short URLs'),
      radioButtons(inputId = 'inputformat',
                   label = 'What type of file are you uploading?',
                   choices = c('Excel' = 'excel', 'CSV' = 'csv')),         
      numericInput(inputId = 'datacol',
                   label = 'Which column are the short URLs in?',
                   value = 1,
                   min = 1,
                   max = 10,
                   step = 1), br(), br(),      
      helpText('Does the short URL column have a header row?'),
      checkboxInput(inputId = 'dataheader',label = 'Yes',value = TRUE), br(),
      fileInput(inputId = 'datafile', label = ''),
      uiOutput('worksheets'), 
      
      h5('Step 2: Get the full URLs'),
      actionButton(inputId = "getlinks", label = "Get Full URLs!", icon = icon("mail-forward")), br(), br(),
      
      
      h5('Step 3: Download the data'),
      radioButtons(inputId = 'outputformat',
                   label = 'In what format would you like to download the data?',
                   choices = c('Excel' = 'excel', 'CSV' = 'csv')),
      downloadButton('downloadlinks','Download Full URLs')      
      ),
    
    mainPanel(
      #textOutput('testing'),  
      h4('How to use this web app'),
        p(strong('Step 1:'), 'Upload a list of short URLs in .csv, .xls, or .xlsx format.
          The data should be in "long format" (sequential rows of a single column).
          If an Excel file is uploaded a dropdown menu will appear so that you can 
          select the appropriate worksheet.'),
        p('There are three tabs to view data. The first shows a summary of the 
          uploaded data file. The second shows the first 10 rows of the the shortened URLs. 
          The third will be blank until the forward URLs are processed.'),
        p(strong('Step 2:'), 'Click "Get Forward URLs" to get the full URLs from their shortened version. 
          This may take several minutes depending on the number of URLs to process. A progress 
          bar will appear along the top of the page that shows the percentage of URLs processed.'),
        p(strong('Step 3:'), 'After the foward urls are processed the file can be downloaded in .csv or .xlsx 
          format by clicking "Download."'),
        a('Click here to download test files', 
          href= 'https://www.dropbox.com/sh/egangmwz6ubg68j/AAAIHt56PzizHDYbq6Jkihh5a?dl=0',
          alt = 'Link to public Dropbox account with test files',
          target = '_blank'), br(), br(),
      
      uiOutput('errortext'),
      
      tabsetPanel(id = "datatabs",
                  tabPanel(title = "Data Summary", value = 'datasumtab', tableOutput('inputsum')),          
                  tabPanel(title = "Input Data", value = 'inputdatatab', tableOutput('inputdata')),
                  tabPanel(title = "Output Data", value = 'outputdatatab', tableOutput('outputdata'))
      )
    )  
  )
))



