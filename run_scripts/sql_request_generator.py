#!/bin/python3
import pymysql
import time
import sys

queries = int(sys.argv[1])
start = time.time()*1000
# Establish a connection
conn = pymysql.connect(
        host="localhost",
        port=10000,
        user="root",
        password="rootpassword"
        #,database="mydatabase"
        )

# Create a cursor object
cursor = conn.cursor()

out = []
# Execute multiple queries
for i in range(queries):
    #cursor.execute("SELECT twitter_handle FROM mydatabase.public_info where user_id='1';")
    cursor.execute("SELECT password FROM mydatabase.users where user_id='1';")
    for row in cursor.fetchall():
        out.append(row)

#print(out)
# Close the connection
cursor.close()
conn.close()
end = time.time()*1000
print(int(end-start))

