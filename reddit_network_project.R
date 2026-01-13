#### SCRIPT PROJECT ####


# Libraries ---------------------------------------------------------------
library(openxlsx)
library(rvest)
library(dplyr)
library(tidyverse)
library(urltools) # library used to detect the domain of a url
library(ngram) # library with the function to calculate the number of words in a text
library(igraph)
library(RSelenium)
library(netstat)
library(wdman)
library(httr)
library(Rcrawler)
library(jsonlite)
library(newsanchor)
library(RedditExtractoR)
library(cld2)
library(cld3)
source("C:/Users/napo2/OneDrive/Desktop/UNI/Magistrale/Anno 2/Web&social_mining/functions/utility.R")


# Thread  -----------------------------------------------------------



#search thread with sinner or alcaraz in the last month in reddit 
sincaraz <- find_thread_urls(subreddit = "tennis",
                             keywords = '"jannik" OR "sinner" OR
                             "carlos" OR "carlitos" OR "alcaraz"',
                             sort_by = "top", period = "month")

#visualization of # threads and comments
sincaraz %>% summarise(threads=n(),tot_comments=sum(comments))
#write.xlsx(list("Foglio1" = sincaraz, "Foglio2" = res.SA), 
#           file = "C:/Users/napo2/OneDrive/Desktop/UNI/Magistrale/Anno 2/Web&social_mining/Project/Dataframes.xlsx")

#date of creation
sincaraz <- sincaraz %>% 
  mutate(created_at = as.POSIXct(timestamp, origin = "1970-01-01"),.after=timestamp)

# # thread by day
sincaraz %>% 
  mutate(day=lubridate::floor_date(created_at,"day")) %>% 
  group_by(day) %>% 
  summarise(threads=n(),min(created_at),max(created_at)) %>% head(5)

#plot: thread by day
sincaraz %>% 
  mutate(day= as.Date(lubridate::floor_date(created_at,"day"))) %>% 
  group_by(day) %>% 
  summarise(threads=n()) %>% 
  ggplot(aes(x=day,y=threads))+
  geom_line(color="brown4",linewidth=1.5)+
  geom_point()+
  scale_x_date(date_breaks = "5 days",date_labels = "%d/%m/%Y")+
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust=1))+
  ggtitle("Thread on Sinner or Alcaraz in the past month by day")

#graph thread, comment and interaction by threads by date
sincaraz %>% 
  mutate(day=as.Date(lubridate::floor_date(created_at,"day"))) %>% 
  group_by(day) %>% 
  summarise(n.threads=n(),n.comments=sum(comments)) %>% 
  mutate(comments.thread=n.comments/n.threads) %>% 
  gather("variable","value",2:4,factor_key = T) %>% 
  ggplot(aes(x=day,y=value,color=variable))+
  geom_line(linewidth=1.2)+
  geom_point()+
  facet_wrap(~variable,scales = "free_y")+
  scale_x_date(date_breaks = "5 days",date_labels = "%d/%m/%Y")+
  ylab(NULL)+
  theme_light()+
  theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust=1))+
  theme(legend.position = "none")+
  ggtitle("Threads and comments on Alcaraz or Sinner in the past month by day")

#order thread by # of comments
sincaraz %>% 
  arrange(-comments) %>% select(created_at,subreddit,title,comments,url) %>%
  as_tibble() %>% head(10)


# Comment  --------------------------------------------------------


#download comments
res.SA <- search_reddit(subreddit = "tennis", q = '"jannik" OR "sinner" OR
                             "carlos" OR "carlitos" OR "alcaraz"',
                        period = "month", sortby = "top", lang = "en", 
                        lang.det.level = 1)

#plot threads/comments by hour
res.SA %>% mutate(day=as.Date(created_at)) %>% 
  mutate(hour=lubridate::floor_date(created_at,"hour")) %>%
  group_by(hour) %>% count() %>% 
  ggplot(aes(x=hour,y=n))+geom_line(color = "brown4", linewidth=1.3)+theme_minimal()+
  scale_x_datetime(date_breaks = "40 hour",date_labels = "%d-%m-%Y %H")+
  theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust=1))+
  ggtitle("Threads/Comments by hour")

#plot threads/comments by day
res.SA %>% mutate(day=as.Date(created_at)) %>% 
  mutate(day=as.Date(lubridate::floor_date(created_at,"day"))) %>%
  group_by(day) %>% count() %>% 
  ggplot(aes(x=day,y=n))+geom_line(color = "brown4", linewidth=1.3)+theme_minimal()+
  scale_x_date(date_breaks = "5 day",date_labels = "%d-%m-%Y %H")+
  theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust=1))+
  ggtitle("Threads/Comments by day")


# Authors -----------------------------------------------------------------



#top authors by # of comments and mean score
res.SA %>% group_by(author) %>% 
  summarise(n=n(),score=mean(score)) %>% 
  arrange(-n) %>% top_n(n = 10,wt = n) 

#boxplot of the 10 most frequent authors
deleted <- "[deleted]"
res.SA <- res.SA %>% group_by(author) %>% filter(!author %in% deleted)
subs <- res.SA %>% group_by(author) %>%  
  summarise(n.post=n()) %>% arrange(-n.post) %>% slice(1:10)
res.SA %>% filter(author %in% subs$author) %>% 
  ggplot(aes(x=author,y=score))+
  geom_boxplot()+
  coord_flip()+theme_minimal()+
  ggtitle("Boxplot of scores of the 10 most frequent authors")

#order by most proficient authors
duser <- res.SA %>% group_by(author) %>% count() %>% arrange(-n)

#get info of the top 5
dAu5 <- reddit.users.info(users = duser$author[1:5])

#karma barplot of the top 5 authors
dAu5$user_info %>% 
  select(name,thread_karma,comment_karma) %>% 
  gather("karma","value",2:3) %>% 
  ggplot(aes(x=name,y=value/1000,fill=karma))+
  geom_col(position = "dodge")+
  scale_fill_manual(values = c("orange2","black"))+
  theme_minimal()+xlab(NULL)+ylab("karma(000)")+
  ggtitle("Karma of the 5 most frequent users")

# Network -----------------------------------------------------------------



#extract info about connections
netSA <- users.reddit.network(res = res.SA)

#comments as a tibble
netSA %>% as_tibble() %>% select(id_thread,From,To)

#network graph
ng <- graph_from_data_frame(d = netSA %>% select(From,To), 
                            directed = T)
V(ng)$size <- log(degree(ng)+1)*1
par(mar=c(0,0,0,0))
plot(ng,
     vertex.label=NA,
     edge.arrow.size=0,
     layout=layout.kamada.kawai(ng))
#it is necessary a simplification

#threads w/ more comments
top_id <- netSA %>% group_by(id_thread) %>% count() %>% arrange(-n) %>% pull(id_thread)

#threads reduction
netSAr <- netSA %>% filter(id_thread %in% top_id[1:3])

#select user and type of the selected threads
dfusers <- netSAr %>% select(id_thread,From,To) %>% gather("type","user",2:3) %>% 
  group_by(user,id_thread) %>% count()

#select a thread for each user, if multiple then 0
dfusers <- dfusers %>% 
  group_by(user) %>% 
  summarise(mi=min(id_thread),ma=max(id_thread)) %>% 
  mutate(thread=ifelse(mi==ma,mi,0)) %>% 
  select(user,thread)

#prepare the reduced network graph
ngr <- graph_from_data_frame(d = netSAr %>% select(From,To), 
                             vertices = dfusers, 
                             directed = T)

# assign color to vertices
V(ngr)$color <- ifelse(V(ngr)$thread==0,"cyan4",ifelse(V(ngr)$thread==top_id[1],"darkred", 
                                                      ifelse(V(ngr)$thread==top_id[2],"orange2","purple3")))

#plot network graph
ngr <- simplify(ngr)
#V(ngr)$size <- (degree(ngr)/max(degree(ngr)))*15
V(ngr)$size <- log(degree(ngr)+1)*3
#V(ngr)$name <-  ifelse(V(ngr)$size<2.5,"",V(ngr)$name)
par(mar=c(0,0,0,0))
plot(ngr,
     vertex.label.cex=0.8,
     edge.arrow.size=0.1,
     layout=layout.kamada.kawai(ngr),
     vertex.label.family="sans")



# Network reduction -------------------------------------------------------

#consider only the 1st thread
netSA_red <- netSA %>% filter(id_thread %in% top_id[1])

dfusers_red <- netSA_red %>% select(id_thread,From,To) %>% gather("type","user",2:3) %>% 
  group_by(user,id_thread) %>% count()

ng_red <- graph_from_data_frame(d = netSA_red %>% select(From,To), 
                             vertices = dfusers_red, 
                             directed = T)

#network of the 1st 3 threads
plot(ng,
     vertex.label=NA,
     edge.arrow.size=0,
     layout=layout.kamada.kawai(ng))

#network of the 1st thread
plot(ng_red,
     vertex.label.cex=0.8,
     edge.arrow.size=0.1,
     layout=layout.kamada.kawai(ng_red),
     vertex.label.family="sans")

#degree of the network
centr_degree(ng)
centr_degree(ngr)
centr_degree(ng_red)

#closeness of the network
centr_clo(ng)
centr_clo(ngr)
centr_clo(ng_red)

#betweenness of the network
centr_betw(ng)
centr_betw(ngr)
centr_betw(ng_red)

# main network statistics
ngr.stat <- c(order=vcount(ngr),
              size=ecount(ngr),
              diameter=diameter(ngr),
              mean_distance=mean_distance(ngr),
              density=edge_density(ngr),
              reciprocity=reciprocity(ngr),
              transitivity=transitivity(ngr,type = "global"))

ng_red.stat <- c(order=vcount(ng_red),
              size=ecount(ng_red),
              diameter=diameter(ng_red),
              mean_distance=mean_distance(ng_red),
              density=edge_density(ng_red),
              reciprocity=reciprocity(ng_red),
              transitivity=transitivity(ng_red,type = "global"))


ngr.stat %>% as.data.frame() %>% rownames_to_column("stat") %>% as_tibble()
ng_red.stat %>% as.data.frame() %>% rownames_to_column("stat") %>% as_tibble()


# community detection -----------------------------------------------------

#edge betweenness
ceb <- cluster_edge_betweenness(ng_red)
length(ceb)

#modularity
modularity(ceb)

# dendrogram of the partition
par(mar=c(3,2,3,1))
plot_dendrogram(ceb, mode="hclust")

#plot
par(mar=c(5,0,1,0))
plot(ceb, ng_red,
     vertex.label.cex=0.7,
     # vertex label color
     vertex.label.color="black",
     edge.arrow.size=.6,
     vertex.label.family="sans",
     vertex.label.font=2,
     layout=layout_with_graphopt(ng_red),
     main="Community on edge betweenness",
     sub=paste("modularity =",round(modularity(ceb),2)))

#fast greedy
cfg <- cluster_fast_greedy(as.undirected(ng_red))
length(cfg) #8

#modularity
modularity(cfg)

#plot
V(ng_red)$community <- cfg$membership
colrs <- adjustcolor( c("gray50", "tomato2", "gold", "yellowgreen","blue3",
                        "purple4","pink3","lightblue2"), alpha=.6)
par(mar=c(0,0,1,0))
plot(as.undirected(ng_red),
     vertex.color=colrs[V(ng_red)$community],
     vertex.label=V(ng_red)$name,
     vertex.label.cex=0.7,
     vertex.label.color="black",
     edge.arrow.size=.6,
     vertex.label.family="sans",
     vertex.label.font=2,
     layout=layout_with_graphopt(ng_red),
     main="Community with fast greedy",
     sub=paste("modularity =",round(modularity(cfg),2), "and", length(cfg), "clusters")) 

par(mar=c(5,0,1,0))
plot(cfg, ng_red,
     vertex.label.cex=0.7,
     # vertex label color
     vertex.label.color="black",
     edge.arrow.size=.6,
     vertex.label.family="sans",
     vertex.label.font=2,
     layout=layout_with_graphopt(ng_red),
     main="Community with fast greedy",
     sub=paste("modularity =",round(modularity(cfg),2), "and", length(cfg), "clusters"))

#Louvain
clo <- cluster_louvain(as.undirected(ng_red))
length(clo)

#modularity
modularity(clo)

#plot
V(ng_red)$community <- clo$membership
colrs <- adjustcolor( c("gray50", "tomato2", "gold", "yellowgreen",
                        "purple4","lightblue2"), alpha=.6)
par(mar=c(0,0,1,0))
plot(as.undirected(ng_red),
     vertex.color=colrs[V(ng_red)$community],
     vertex.label=V(ng_red)$name,
     vertex.label.cex=0.7,
     vertex.label.color="black",
     edge.arrow.size=.6,
     vertex.label.family="sans",
     vertex.label.font=2,
     layout=layout_with_graphopt(ng_red),
     main="Community with Louvain") 

#par(mar=c(5,0,1,0))
#plot(clo, as.undirected(ng_red),
#     vertex.label.cex=0.7,
#     vertex.label.color="black",
#    edge.arrow.size=.6,
#     vertex.label.family="sans",
#     vertex.label.font=2,
#     layout=layout_with_graphopt(ng_red),
#     main="Community with louvain",
#     sub=paste("modularity =",round(modularity(clo),2), "and", length(clo), "clusters")) 


#Leiden
cle <- cluster_leiden(as.undirected(ng_red),objective_function = "modularity")
length(cle) #7

#Modularity
modularity(as.undirected(ng_red),
           membership = cle$membership,
           weights = E(as.undirected(ng_red))$weight)

#plot
V(ng_red)$community <- cle$membership
colrs <- adjustcolor( c("gray50", "darkgreen", "gold", "yellowgreen",
                        "purple4","lightblue2","darkred"), alpha=.6)
par(mar=c(0,0,1,0))
plot(as.undirected(ng_red),
     vertex.color=colrs[V(ng_red)$community],
     vertex.label=V(ng_red)$name,
     vertex.label.cex=0.7,
     vertex.label.color="black",
     edge.arrow.size=.6,
     vertex.label.family="sans",
     vertex.label.font=2,
     layout=layout_with_graphopt(ng_red),
     main="Community with Leiden") 

#plot(cle,as.undirected(ng_red),
#     vertex.label.cex=0.7,
#     vertex.label.color="black",
#     edge.arrow.size=.6,
#     vertex.label.family="sans",
#     vertex.label.font=2,
#     layout=layout_with_graphopt(ng_red),main="Community with leiden",
#     sub=paste("modularity =",round(modularity(as.undirected(ng_red),
#                                               membership = cle$membership,
#                                               weights = E(as.undirected(ng_red))$weight),2)))


#Leading non-negative eigenvector
cev <- cluster_leading_eigen(as.undirected(ng_red))
length(cev)

#modularity
modularity(cev)

#plot
plot(cev,as.undirected(ng_red),
     vertex.label.cex=0.7,
     vertex.label.color="black",
     edge.arrow.size=.6,
     vertex.label.family="sans",
     vertex.label.font=2,
     layout=layout_with_graphopt(ng_red),main="Community with leiden non-negative eigenvector",
     sub=paste("modularity =",round(modularity(cev),2)))

#Walktrap
cwt <- cluster_walktrap(ng_red)
length(cwt)

#modularity
modularity(cwt)

#plot
plot(cwt,as.undirected(ng_red),
     vertex.label.cex=0.7,
     vertex.label.color="black",
     edge.arrow.size=.6,
     vertex.label.family="sans",
     vertex.label.font=2,
     layout=layout_with_graphopt(ng_red),main="Community with Walktrap",
     sub=paste("modularity =",round(modularity(cwt),2)))
