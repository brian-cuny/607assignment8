library(RMySQL)
library(RNeo4j)
library(tidyverse)
library(purrrlyr)

sql.password <- 'cosmic joke'
neo4j.password <- 'asdfasdf'

mydb <- dbConnect(MySQL(), user='root', password=sql.password, dbname='week2assignment', host='localhost')

all.data <- dbSendQuery(mydb, 'SELECT users.user_id AS id, users.email, reviews.movie AS title, reviews.rating FROM users JOIN reviews ON users.user_id = reviews.user_id') %>%
  fetch() %>%
  filter(!is.na(rating))

graph <- startGraph('http://localhost:7474/db/data/', username='neo4j', password=neo4j.password)

clear(graph)

addConstraint(graph, 'User', 'email')
addConstraint(graph, 'User', 'id')
addConstraint(graph, 'Movie', 'title')

query <- '
MERGE (user:User {id: {id}, email:{email}})
MERGE (movie:Movie {title: {title}})
CREATE (user)-[r:REVIEWS]->(movie)
SET r.rating = TOINT({rating})
'
tx <- newTransaction(graph)

for(i in 1:nrow(all.data)){
  row <- all.data[i, ]
  
  appendCypher(tx, query,
               email = row$email,
               id = row$id,
               rating = row$rating,
               title = row$title)
}

commit(tx)

summary(graph)

# analysis ----------------------------------------------------------------

cypher.query <- cypher(graph, 'MATCH (u:User)-[r:REVIEWS]->(m:Movie), (u2:User)-[r2:REVIEWS]->(m2:Movie) WHERE u.id <> u2.id AND m.title = m2.title AND r.rating = r2.rating RETURN u.id, u2.id, COUNT(*);')





