# 🎾🌐 Reddit Tennis Network Analysis – Sinner & Alcaraz

An R project that collects, analyzes, and visualizes Reddit discussions about **Jannik Sinner** and **Carlos Alcaraz** from the r/tennis subreddit, with a focus on **social network analysis** and **community detection**.

---

## 📋 Description

This project scrapes Reddit threads and comments mentioning Sinner or Alcaraz from the past month, performs exploratory analysis on posting patterns and user behavior, and builds a **directed interaction network** between users. Multiple community detection algorithms are applied and compared to identify clusters of interaction within the network.

---

## 🔍 Project Workflow

### 1. 🧵 Thread Analysis
- Retrieves top threads from r/tennis mentioning Sinner or Alcaraz
- Analyzes posting frequency by day
- Ranks threads by number of comments

### 2. 💬 Comment Analysis
- Downloads comments using `RedditExtractoR`
- Plots activity by hour and by day
- Filters English-language content

### 3. 👤 Author Analysis
- Identifies the most active users by number of comments and average score
- Visualizes score distribution via boxplots
- Fetches karma stats for the top 5 most frequent authors

### 4. 🕸️ Network Analysis
- Builds a **directed interaction network** from user reply chains
- Visualizes the full network and a reduced version (top 3 threads)
- Computes key network metrics: degree, closeness, betweenness, diameter, density, reciprocity, transitivity

### 5. 🔎 Community Detection
Applies and compares five algorithms:
- **Edge Betweenness**
- **Fast Greedy**
- **Louvain**
- **Leiden**
- **Leading Eigenvector**
- **Walktrap**

---

## 📦 Dependencies

Install all required R packages:

```r
install.packages(c(
  "openxlsx", "rvest", "dplyr", "tidyverse", "urltools",
  "ngram", "igraph", "RSelenium", "netstat", "wdman",
  "httr", "Rcrawler", "jsonlite", "newsanchor",
  "RedditExtractoR", "cld2", "cld3"
))
```

---

## 💻 Usage

1. Open `reddit_network_project.R` in RStudio
2. Update the `source()` path to point to your local `utility.R` file:
   ```r
   source("path/to/your/utility.R")
   ```
3. Run the script section by section:
   - **Thread** → scraping and temporal analysis
   - **Comment** → activity plots
   - **Authors** → user profiling
   - **Network** → graph construction and metrics
   - **Network reduction** → focused analysis on top threads
   - **Community detection** → clustering algorithms

---

## 📁 Project Structure

```
reddit-network-project/
│
├── reddit_network_project.R      # Main analysis script
├── functions/
│   └── utility.R                 # Custom utility functions
├── Dataframes.xlsx               # Exported data (generated)
└── README.md
```

---

## 📊 Output

- Time series plots of threads and comments by day/hour
- Boxplots of author score distributions
- Karma bar charts for top users
- Network graphs (full, reduced, community-colored)
- Dendrograms of community partitions
- Network statistics tables (order, size, diameter, density, reciprocity, transitivity)

---

## 🌐 Data Source

Data collected from [Reddit – r/tennis](https://www.reddit.com/r/tennis/) via the [`RedditExtractoR`](https://github.com/ivan-rivera/RedditExtractor) package. Please respect Reddit's [API Terms of Service](https://www.reddit.com/wiki/api).

---

## 📄 License

This project was developed for academic purposes as part of a Web & Social Mining course.
