from pg8000.native import Connection


def execute(conn: Connection, query: str, print_query: bool = True):
    if print_query:
        print(f"{conn.user.decode('utf-8')}> {query}")
    return conn.run(query)
