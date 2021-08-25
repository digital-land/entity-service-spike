import csv
import logging
import os
import random
import time

import boto3
import mysql.connector

from retrying import retry

logger = logging.getLogger(__name__)

ENDPOINT = "database-1.cluster-czb2e1jr2ad8.eu-west-2.rds.amazonaws.com"
DBNAME = "test"
PORT = "3306"
USR = "admin"
REGION = "eu-west-2"
os.environ["LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN"] = "1"


class Datastore:
    conn = None

    def connect(self):
        try:
            logger.info("connecting to RDS")
            self.conn = mysql.connector.connect(
                host=ENDPOINT,
                user=USR,
                passwd="dbpassword",
                port=PORT,
                database=DBNAME,
                pool_name="mypool",
                pool_size=8,
                # ssl_ca="/Users/bram/Downloads/eu-west-2-bundle.pem",
            )
            # cur = conn.cursor()
            # cur.execute("""SELECT now()""")
            # query_results = cur.fetchall()
            # print(query_results)
        except Exception as e:
            print("Database connection failed due to {}".format(e))

    @retry(stop_max_attempt_number=10, wait_fixed=500)
    def lookup(self, alias):
        conn = mysql.connector.connect(pool_name="mypool")
        qry = "SELECT id FROM slug WHERE BINARY slug = %s"
        try:
            cur = conn.cursor()
            cur.execute(qry, (alias,))
            result = cur.fetchall()
            if cur.rowcount != 1:
                print(f"expected 1 row, {cur.rowcount} returned [{qry % alias}]")
                return None
        except mysql.connector.errors.OperationalError:
            raise Exception("Lost db connection")
        finally:
            conn.close()
        return result[0][0]


datastore = Datastore()
