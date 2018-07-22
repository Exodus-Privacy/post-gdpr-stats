# Description
This [R script](https://www.r-project.org/) is meant to plot statistics based on Exodus Privacy reports issued before and after the GDPR day. The goal is to evaluate the impact of the GDPR on the number of trackers embedded in Android applications.

The script will automatically ignore applications for which Exodus Privacy does not have reports issued before and after the GDPR day.

# Requirements
To run the `post_gdpr_stats.r` script, you have to [install R](https://pbil.univ-lyon1.fr/CRAN/).

# Usage
The `post_gdpr_stats.r` script takes 3 positional parameters:
* the path where plots will be saved
* the name of your current study like *Popular* for popular applications, this name will be used as plot title
* the file containing a list of application handles (one per line) to take in account. This file has to have an empty line at its end.

To execute this script, run the following command line:
```
Rscript --vanilla post_gdpr_stats.r $PWD Popular popular.txt
```

# Application list file
The `app_list.js` can be pasted in your browser JS console when you visit a Google Play store page listing applications ([the popular category](https://play.google.com/store/apps/collection/topselling_free)). The script with replace the content of the web page with the list of applications found in the page. Just copy and paste this list into a file and specify this file as the third parameter of the `post_gdpr_stats.r` script.

# Step-by-step - Linux
First of all, you have to [install R](https://pbil.univ-lyon1.fr/CRAN/).

### Install R on `debian`'s like systems: 
`sudo apt-get install r-base r-base-dev`

#### This script need specifics dependencies which had to be installed too:
`sudo apt-get install r-cran-ggplot2 r-cran-rjson`

Then, clone or download this Git repository:
```
cd $HOME
git clone https://github.com/Exodus-Privacy/post-gdpr-stats.git
cd post-gdpr-stats
```

Run the R script on the example of application list: 
```
Rscript --vanilla post_gdpr_stats.r $PWD "My example" example/popular.txt
```

3 plots have been saved:
* My example-evolution.png
* My example-trackers_now.png
* My example-worse_or_better.png

![](example/My_example-evolution.png?raw=true)
![](example/My_example-trackers_now.png?raw=true)
![](example/My_example-worse_or_better.png?raw=true)
