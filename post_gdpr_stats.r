#!/usr/bin/env Rscript
list.of.packages <- c("ggplot2", "rjson")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
library("rjson")
library("ggplot2")

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 3) {
  stop("You have to pass 3 arguments: export_path run_name list_of_apps_file", call.=FALSE)
}

EXPORT_PATH = as.character(args[1])
RUN_NAME = as.character(args[2])
APP_LIST = as.character(args[3])

get_top_reports <- function(app_list_file){
  top_apps <-readLines(file(app_list_file, "r"))
  reports <- c()
  for(app in top_apps){
    url <- sprintf("https://reports.exodus-privacy.eu.org/api/search/%s", app)
    result <- tryCatch({rjson::fromJSON(file=url)}, error = function(e) {return(list())})
    if(length(result) == 1){
      reports <- c(reports, result)
      print(paste("Found -", app))
    } else {
      print(paste("Error -", app))
    }
  }
  return(reports)
}

before_rgpday <- function(d) {
  rgpd <- as.numeric(as.POSIXct("2018-05-25"))
  appd <- as.numeric(as.POSIXct(d))
  return(appd < rgpd)
}

after_rgpday <- function(d) {
  rgpd <- as.numeric(as.POSIXct("2018-05-25"))
  appd <- as.numeric(as.POSIXct(d))
  return(appd > rgpd)
}

get_latest_report <- function(reports) {
  latest <- NULL
  last = 0
  for(r in reports){
    if(as.numeric(as.POSIXct(r$creation_date)) > last) {
      last <- as.numeric(as.POSIXct(r$creation_date))
      latest <- r
    }
  }
  return(latest)
}

get_number_of_trackers <- function(reports) { 
  a <- c()
  for(r in reports) {
    a <- c(a, length(r$trackers))
  }
  return(a)
}

strim <- function(s, l) {
  after <- strtrim(s, l-4)
  if(nchar(after) < nchar(s)){
    return(paste(after, "..."))
  } else {
    return(s)
  }
}

find_candidates <- function(reports) {
  name <- c()
  handle <- c()
  before <- c()
  after <- c()
  state <- c()
  diff <- c()
  clean <- c()
  trackers_now <- c()
  candidates <- list()
  count_better = 0
  count_worse = 0
  num_better <- list()
  num_worse <- list()
  for(h in names(reports)) {
    reports_before <- list()
    reports_after <- list()
    val <- reports[[h]]
    has_before_rgpd <- FALSE
    has_after_rgpd <- FALSE
    for(r in val$reports) {
      has_before_rgpd <- has_before_rgpd || before_rgpday(r$creation_date)
      has_after_rgpd <- has_after_rgpd || after_rgpday(r$creation_date)
      if(before_rgpday(r$creation_date)) {
        reports_before <- c(reports_before, list(r))
      }
      if(after_rgpday(r$creation_date)) {
        reports_after <- c(reports_after, list(r))
      }
    }
    if(has_before_rgpd && has_after_rgpd) {
      ra = mean(get_number_of_trackers(reports_after))
      trackers_after = length(get_latest_report(reports_after)$trackers)
      # trackers_after = min(get_number_of_trackers(reports_after))
      rb = mean(get_number_of_trackers(reports_before))
      trackers_before = length(get_latest_report(reports_before)$trackers)
      # trackers_before = max(get_number_of_trackers(reports_before))
      if(exists('name', where = val)){
        name <- c(name, strim(val$name, 32))
      } else{
        name <- c(name, h)
      }
      handle <- c(handle, h)
      before <- c(before, trackers_before)
      after <- c(after, trackers_after)
      if(trackers_after > trackers_before){
        state <- c(state, "Worse")
      }
      else if(trackers_after < trackers_before){
        state <- c(state, "Better")
      }
      else{
        state <- c(state, "No change")
      }
      diff <- c(diff, trackers_after - trackers_before)
      clean <- c(clean, trackers_after ==0)
      candidates[[h]] <- list(name=val$name, 
                        reports_before = reports_before, 
                        reports_after = reports_after, 
                        trackers_before = rb,
                        trackers_after = ra,
                        worse = trackers_after > trackers_before,
                        better = trackers_after < trackers_before,
                        diff = trackers_after - trackers_before,
                        is_clear = trackers_after == 0
      )
      if((trackers_after - trackers_before) < 0){
        count_better = count_better + 1
        num_better <- c(num_better, trackers_before - ra)
      }
      if((trackers_after - trackers_before) > 0){
        count_worse = count_worse + 1
        num_worse <- c(num_worse, trackers_after - trackers_before)
      }
    }
    if(!has_after_rgpd){
      print(paste(h, "- no data after GDPR, submit this application to exodus and relaunch this script"))
    }
    if(!has_before_rgpd){
      print(paste(h, "- no data before GDPR - IGNORED"))
    }
  }
  d <- data.frame(handle)
  d$name <- c(name)
  d$before <- c(before)
  d$after <- c(after)
  d$state <- c(state)
  d$diff <- c(diff)
  d$clean <- c(clean)
  return(c(d_frame = list(d), candidates = list(candidates), better = count_better, worse = count_worse, num_better = list(num_better), num_worse = list(num_worse)))
}

top_reports <- get_top_reports(APP_LIST)

export_path <- sprintf("%s/%s", EXPORT_PATH, RUN_NAME)
label <- paste("Data from Exodus Privacy -", format(Sys.Date(), format="%Y-%m-%d"))

stats <- find_candidates(top_reports)
d <- stats$d_frame
if(length(d) < 2){
  stop("No enough data", call.=FALSE)
}
states <- c("No change", "Worse", "Better")
count <- c(length(d[d$state=="No change",]$name), length(d[d$state=="Worse",]$name), length(d[d$state=="Better",]$name))
f <- data.frame(states, count)
ggplot(f, aes(x=reorder(states, count), y=count, fill=states)) + 
  geom_bar(stat="identity") + 
  xlab("Number of trackers evolution post-GDPR") + 
  ylab("Number of applications") +
  scale_fill_manual(values = c("No change" = "#424b54", "Worse" = "#da3b20", "Better" = "#0cc97a")) + 
  theme(legend.position="none") + 
  labs(caption = label, title = RUN_NAME) +
  theme(axis.text.x=element_text(colour="#684971", family = "AvantGarde"), 
        axis.text.y=element_text(colour="#684971", family = "AvantGarde")) + 
  theme(axis.title.x=element_text(colour="#684971", family = "AvantGarde", face = "bold"), 
        axis.title.y=element_text(colour="#684971", family = "AvantGarde", face = "bold"),
        plot.caption = element_text(colour="#684971", family = "AvantGarde", size = 8),
        plot.title = element_text(colour="#684971", family = "AvantGarde", size = 14, face = "bold"))

path = sprintf("%s-%s", export_path, "worse_or_better.png")
ggsave(path, width = 14, height = 14, units = "cm")

ggplot(d, aes(x=reorder(name, diff), y=diff, fill=as.character(clean))) + 
  geom_bar(stat="identity") + 
  scale_fill_manual(name = "No more trackers", values = c("TRUE" = "#0cc97a",  "FALSE" = "#684971")) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5)) + 
  theme(panel.grid.major = element_line(colour = "#b4b4b4", size = 0.1)) +
  theme(panel.grid.minor = element_line(colour = "#b4b4b4", size = 0.1)) +
  theme(legend.position="bottom", 
        legend.text = element_text(colour="#424b54", size=8), 
        legend.title = element_text(colour="#684971", size=8)) + 
  xlab("Applications") + 
  ylab("Number of trackers difference post-GDPR") +
  labs(caption = label, title = RUN_NAME) +
  theme(axis.text.x=element_text(colour="#684971", family = "AvantGarde"), 
        axis.text.y=element_text(colour="#684971", family = "AvantGarde")) + 
  theme(axis.title.x=element_text(colour="#684971", family = "AvantGarde", face = "bold"), 
        axis.title.y=element_text(colour="#684971", family = "AvantGarde", face = "bold"),
        plot.caption = element_text(colour="#684971", family = "AvantGarde", size = 8),
        plot.title = element_text(colour="#684971", family = "AvantGarde", size = 14, face = "bold"))

path = sprintf("%s-%s", export_path, "evolution.png")
ggsave(path, width = 35, height = 24, units = "cm")

ggplot(d, aes(x=reorder(name, after), y=after, fill=as.character(clean), label=after)) + 
  geom_bar(stat="identity", fill = "#684971") + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5)) + 
  theme(panel.grid.major = element_line(colour = "#b4b4b4", size = 0.1)) +
  theme(panel.grid.minor = element_line(colour = "#b4b4b4", size = 0.1)) +
  theme(legend.position="bottom", 
        legend.text = element_text(colour="#424b54", size=8), 
        legend.title = element_text(colour="#684971", size=8)) + 
  xlab("Applications") + 
  ylab("Number of trackers in the latest report") +
  geom_text(size = 3, position = position_stack(vjust = 0.5)) +
  labs(caption = label, title = RUN_NAME) +
  theme(legend.position="none") + 
  theme(axis.text.x=element_text(colour="#684971", family = "AvantGarde"), 
        axis.text.y=element_text(colour="#684971", family = "AvantGarde")) + 
  theme(axis.title.x=element_text(colour="#684971", family = "AvantGarde", face = "bold"), 
        axis.title.y=element_text(colour="#684971", family = "AvantGarde", face = "bold"),
        plot.caption = element_text(colour="#684971", family = "AvantGarde", size = 8),
        plot.title = element_text(colour="#684971", family = "AvantGarde", size = 14, face = "bold"))

path = sprintf("%s-%s", export_path, "trackers_now.png")
ggsave(path, width = 35, height = 24, units = "cm")