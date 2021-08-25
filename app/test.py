import asyncio
import csv
import os
import random
import statistics
import time

import aiohttp
import boto3
import mysql.connector
import requests

ENDPOINT = "database-1.cluster-czb2e1jr2ad8.eu-west-2.rds.amazonaws.com"
DBNAME = "test"
PORT = "3306"
USR = "admin"
REGION = "eu-west-2"
os.environ["LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN"] = "1"

# gets the credentials from .aws/credentials
session = boto3.Session(profile_name="dl-dev")
client = session.client("rds", region_name=REGION)

# token = client.generate_db_auth_token(
#     DBHostname=ENDPOINT, Port=PORT, DBUsername=USR, Region=REGION
# )


def run_perf_test(conn):
    print("loading data")
    data = load_data("/Users/bram/Downloads/slug.csv")
    print("shuffling data")
    random.shuffle(data)
    print("running performance test")
    start_time = time.time()
    count = 0
    for row in data:
        count += 1
        if count % 100 == 0:
            split = time.time() - start_time
            print(f"{count} lookups completed in {split} seconds ({count/split}/s)")
        # result = get(conn, row["slug"])
        result = get_http(row["slug"])
        assert result == int(row["id"])

    elapsed = time.time() - start_time
    print(f"{len(data)} lookups completed in {elapsed} seconds")
    print(f"{len(data) / elapsed} lookups per second")


def get_http(slug):
    host = "http://entity-lookup-lb-1858719551.eu-west-2.elb.amazonaws.com"
    url = f"{host}/entity"
    payload = {"alias": slug}
    # print(f"querying {url}")
    resp = requests.get(url, payload=payload)
    return int(resp.text)


async def run_perf_test_async(conn):
    print("loading data")
    data = load_data("/Users/bram/Downloads/slug.csv")
    print("shuffling data")
    random.shuffle(data)
    print("running performance test")
    chunksize = 5000
    count = 0
    # data = list(filter(lambda x: x["slug"] == "/development-plan-document/local-authority-eng/SWS;local-authority-eng/WIL/waste-strategy-sws-wil-xyz", data))
    # __import__('pdb').set_trace()
    async with aiohttp.ClientSession() as session:
        for chunk in [data[i : i + chunksize] for i in range(0, len(data), chunksize)]:
            tasks = []
            for row in chunk:
                count += 1
                # if count % 100 == 0:
                #     split = time.time() - start_time
                #     print(f"{count} lookups completed in {split} seconds ({count/split}/s)")
                # result = get(conn, row["slug"])
                # result = await get_aiohttp(session, row["slug"])
                tasks.append(get_verify(session, row["slug"], row["id"], count))

            start_time = time.time()
            request_times = await asyncio.gather(*tasks)
            elapsed = time.time() - start_time
            print(f"{chunksize} lookups completed in {elapsed} seconds")
            print(f"{chunksize / elapsed} lookups per second")
            print(f"min: {min(request_times)}")
            print(f"max: {max(request_times)}")
            print(f"avg: {statistics.mean(request_times)}")


async def get_verify(session, slug, value, count):
    host = "http://dl-web-lb-2054476702.eu-west-2.elb.amazonaws.com"
    # host = "http://127.0.0.1"
    url = f"{host}/entity"
    payload = {"alias": slug}
    # print(f"{count}: getting {url}")
    start = time.time()
    result = await get_aiohttp(session, url, payload)
    # print(result)
    elapsed = time.time() - start
    # print(f"asserting {result} == {value}")
    assert (
        result == value
    ), f"{result} ({type(result)})!= {value} ({type(value)}) [{url}, {payload}]"
    return elapsed


async def get_aiohttp(session, url, payload):
    try:
        async with session.get(url, params=payload) as resp:
            # resp = requests.get(url)
            if resp.status != 200:
                print(resp.status)
                raise Exception(f"response code {resp.status} [{url} {payload}]")
            return await resp.text()
    except aiohttp.ClientConnectorError as e:
        print("Connection Error", str(e))


def get(conn, slug):
    qry = "select id from slug where slug = %s"
    cur = conn.cursor()
    cur.execute(qry, (slug,))
    id_ = cur.fetchall()
    assert cur.rowcount == 1, f"expected 1 row, {cur.rowcount} returned [{qry}]"
    cur.close()
    return id_[0][0]


def load_data(path):
    result = []
    count = 0
    for row in csv.DictReader(open(path)):
        count += 1
        result.append(row)
    print("%s rows loaded" % count)
    return result


try:
    conn = mysql.connector.connect(
        host=ENDPOINT,
        user=USR,
        passwd="dbpassword",
        port=PORT,
        database=DBNAME,
        ssl_ca="/Users/bram/Downloads/eu-west-2-bundle.pem",
    )
except Exception as e:
    print("Database connection failed due to {}".format(e))

# run_perf_test(conn)
asyncio.run(run_perf_test_async(conn))
