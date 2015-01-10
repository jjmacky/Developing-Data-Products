# Custom function to get forward links
getFwLinks = function(links, dataCol) {
  # Cleanup data
  #links[, dataCol] = gsub("#TXT", "", links[, dataCol])
  
  total = nrow(links)
  FwLinks = vector(mode = "character", length = total) # Create results vector
  withProgress(min = 0, max = total, message = paste(total, "rows detected. Getting forward links..."), {
    # Loop through all of the links and get the froward link, checking for errors
    for(i in 1:total) {
      setProgress(value = i)
      url = links[i,dataCol]
      
      possibleError = tryCatch ({
        FwLink = getURL(url, sslversion=3L, ssl.verifyhost = FALSE, ssl.verifypeer = FALSE)
        FwLinkParse = htmlParse(FwLink)
        FwLinkFinal = xpathSApply(FwLinkParse, "//a/@href")
      },
      error = function(e) {  FwLinks[i] = "Error in RCurl or XML functions" }
      )
      
      if(!is.null(FwLinkFinal)) {
        FwLinks[i] = FwLinkFinal
        
      } else {
        FwLinks[i] = "URL Not Found"
      }
    }
  })
  return(cbind.data.frame(links,FwLinks))
}